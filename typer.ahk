; random_enter_loop_fixed.ahk
; AutoHotkey v1
; Отправляет фразы из insults.txt
; 30% шанс — разбивать фразу на слова и отправлять по одному слову на Enter
; Опечатки — только соседние русские клавиши (без удаления)
; F1 — вкл/выкл скрипта
; F2 — CAPS режим
; F3 — ручное включение/выключение второго шаблона (триггера)
; F4 — ручной split-режим (по словам)
; Ctrl+Alt+S — выход
; Без задержек

#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%

InsultsFile := A_ScriptDir "\insults.txt"
TriggerFile := A_ScriptDir "\insults_trigger.txt"

; --- ПРОВЕРКА ОСНОВНОГО ФАЙЛА ---
if !FileExist(InsultsFile) {
    MsgBox, 48, Ошибка, Файл insults.txt не найден.
    ExitApp
}
FileRead, content, %InsultsFile%
if (content = "") {
    MsgBox, 48, Ошибка, Файл insults.txt пуст.
    ExitApp
}

; --- НАСТРОЙКИ ---
typoChance := 40
minTypos   := 2
maxTypos   := 4
splitChance := 1

; --- ЧТЕНИЕ ОСНОВНЫХ СТРОК ---
AllLines := []
seen := {}
Loop, Parse, content, `n, `r
{
    line := Trim(A_LoopField)
    if (line != "" && !seen.HasKey(line)) {
        AllLines.Push(line)
        seen[line] := true
    }
}
if (AllLines.Length() = 0) {
    MsgBox, 48, Ошибка, Нет строк для вставки.
    ExitApp
}

; --- ЧТЕНИЕ ВТОРОГО ФАЙЛА (триггерного) ---
TriggerLines := []
if FileExist(TriggerFile) {
    FileRead, content2, %TriggerFile%
    if (content2 != "") {
        seen2 := {}
        Loop, Parse, content2, `n, `r
        {
            line2 := Trim(A_LoopField)
            if (line2 != "" && !seen2.HasKey(line2)) {
                TriggerLines.Push(line2)
                seen2[line2] := true
            }
        }
    }
}

; --- СЛОВАРЬ СОСЕДЕЙ ---
neighbors := {}
neighbors["й"] := "цф"
neighbors["ц"] := "йуыф"
neighbors["у"] := "цкыв"
neighbors["к"] := "уеав"
neighbors["е"] := "кнап"
neighbors["н"] := "егпр"
neighbors["г"] := "нрош"
neighbors["ш"] := "глощ"
neighbors["щ"] := "шздл"
neighbors["з"] := "щхдж"
neighbors["х"] := "зъэж"
neighbors["ъ"] := "хэ"
neighbors["ф"] := "йцыя"
neighbors["ы"] := "фцувяч"
neighbors["в"] := "ыукасч"
neighbors["а"] := "вкепсм"
neighbors["п"] := "аенрио"
neighbors["р"] := "пногтио"
neighbors["о"] := "ргшлтд"
neighbors["л"] := "оощдтжь"
neighbors["д"] := "лзжэбь"
neighbors["ж"] := "дэхюб"
neighbors["э"] := "жхъю"
neighbors["я"] := "фыч"
neighbors["ч"] := "яывсшм"
neighbors["с"] := "чваим"
neighbors["м"] := "сапитч"
neighbors["и"] := "мпртс"
neighbors["т"] := "иролмьб"
neighbors["ь"] := "тлдб"
neighbors["б"] := "ьдэжю"
neighbors["ю"] := "бжэ"

; --- ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ---
Available := []
capsMode := false
scriptEnabled := true
currentWords := []
currentWordIndex := 0
splitMode := false
manualSplitMode := false
triggeredMode := false

; --- ФУНКЦИИ ---
ResetCycle() {
    global Available, AllLines
    Available := []
    temp := []
    for each, l in AllLines
        temp.Push(l)
    Loop % temp.Length()
    {
        Random, j, A_Index, % temp.Length()
        t := temp[A_Index]
        temp[A_Index] := temp[j]
        temp[j] := t
    }
    Available := temp
}

ActivateTriggeredMode() {
    global triggeredMode, Available, TriggerLines
    if (!IsObject(TriggerLines) || TriggerLines.Length() = 0)
        return
    triggeredMode := true
    Available := []
    temp := []
    for each, l in TriggerLines
        temp.Push(l)
    Loop % temp.Length()
    {
        Random, j, A_Index, % temp.Length()
        t := temp[A_Index]
        temp[A_Index] := temp[j]
        temp[j] := t
    }
    Available := temp
}

ShowNextHint() {
    global Available, scriptEnabled, capsMode, triggeredMode, manualSplitMode
    if (!scriptEnabled) {
        ToolTip, (скрипт выключен)
        return
    }
    suffix := ""
    if (capsMode)
        suffix .= " (CAPS)"
    if (triggeredMode)
        suffix .= " [🔥Второй шаблон]"
    if (manualSplitMode)
        suffix .= " [SPLIT]"
    if (Available.Length() > 0) {
        next := Available[Available.Length()]
        MouseGetPos, mx, my
        ToolTip, Следующее: %next%%suffix%, %mx%, %my%+20
    } else {
        ToolTip, Следующее: (начнётся новый цикл)%suffix%
    }
}

HideHint() {
    ToolTip
}

MakeTypos(text) {
    global typoChance, minTypos, maxTypos, neighbors
    StringLen, len, text
    if (len < 1)
        return text
    Random, chanceAny, 1, 100
    if (chanceAny > typoChance)
        return text
    Random, typoCount, %minTypos%, %maxTypos%
    Loop %typoCount% {
        StringLen, len, text
        if (len < 1)
            break
        Random, pos, 1, %len%
        Random, typoType, 1, 3
        StringMid, orig, text, pos, 1
        origLower := orig
        StringLower, origLower, origLower
        if (typoType = 1) {
            if (pos < len) {
                StringMid, c1, text, pos, 1
                StringMid, c2, text, pos+1, 1
                StringLeft, part1, text, pos-1
                StringMid, part3, text, pos+2, len
                text := part1 . c2 . c1 . part3
            }
        } else if (typoType = 2) {
            if (neighbors.HasKey(origLower)) {
                set := neighbors[origLower]
                setLen := StrLen(set)
                if (setLen >= 1) {
                    Random, idx, 1, %setLen%
                    StringMid, newChar, set, idx, 1
                    if (orig ~= "[А-Я]")
                        StringUpper, newChar, newChar
                    StringLeft, part1, text, pos-1
                    StringMid, part2, text, pos+1, len
                    text := part1 . newChar . part2
                }
            }
        } else {
            StringLeft, part1, text, pos
            StringMid, part2, text, pos+1, len
            text := part1 . orig . part2
        }
    }
    return text
}

; --- ИНИЦИАЛИЗАЦИЯ ---
ResetCycle()
ShowNextHint()

; --- ENTER ---
EnterHandler:
    global scriptEnabled, Available, capsMode, splitChance
    global currentWords, currentWordIndex, splitMode, manualSplitMode

    if (!scriptEnabled)
        return

    if (splitMode) {
        if (currentWordIndex < currentWords.Length()) {
            currentWordIndex++
            word := currentWords[currentWordIndex]
            typoed := MakeTypos(word)
            if (capsMode)
                StringUpper, typoed, typoed
            SendInput %typoed%{Enter}
            if (currentWordIndex >= currentWords.Length()) {
                splitMode := false
                currentWords := []
                currentWordIndex := 0
                ShowNextHint()
            }
            return
        } else {
            splitMode := false
            currentWords := []
            currentWordIndex := 0
        }
    }

    if (Available.Length() = 0)
        ResetCycle()
    chosen := Available.Pop()
    chosen := Trim(chosen)

    Random, chance, 1, 100
    if (manualSplitMode || chance <= splitChance) {
        words := StrSplit(chosen, A_Space)
        cleanWords := []
        for i, w in words {
            w := Trim(w)
            if (w != "")
                cleanWords.Push(w)
        }
        if (cleanWords.Length() > 1) {
            splitMode := true
            currentWords := cleanWords
            currentWordIndex := 1
            word := currentWords[currentWordIndex]
            typoed := MakeTypos(word)
            if (capsMode)
                StringUpper, typoed, typoed
            SendInput %typoed%{Enter}
            return
        }
    }

    typoed := MakeTypos(chosen)
    if (capsMode)
        StringUpper, typoed, typoed
    SendInput %typoed%{Enter}
    ShowNextHint()
return

Hotkey, Enter, EnterHandler, On

; --- F1 ---
F1::
    scriptEnabled := !scriptEnabled
    if (scriptEnabled) {
        Hotkey, Enter, EnterHandler, On
        ShowNextHint()
    } else {
        Hotkey, Enter, EnterHandler, Off
        HideHint()
    }
return

; --- F2 ---
F2::
    capsMode := !capsMode
    ShowNextHint()
return

; --- F3: ручное включение второго шаблона ---
F3::
    global triggeredMode
    if (!triggeredMode) {
        ActivateTriggeredMode()
    } else {
        triggeredMode := false
        ResetCycle()
        ToolTip, 🔁 Вернулись к обычным фразам
        SetTimer, HideHint, -1500
    }
    ShowNextHint()
return

; --- F4: ручной split ---
F4::
    manualSplitMode := !manualSplitMode
    msg := manualSplitMode ? "🔠 Split режим ВКЛ" : "Split режим ВЫКЛ"
    ToolTip, %msg%
    SetTimer, HideHint, -1500
    ShowNextHint()
return

; --- Ctrl+Alt+S ---
^!s::
    HideHint()
    ExitApp
return