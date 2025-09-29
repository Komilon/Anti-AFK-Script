#Requires AutoHotkey v2.0
#SingleInstance Force

; Проверка на уже запущенный скрипт
if ProcessExist("AutoHotkey.exe") {
    existingProcesses := ""
    for process in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process where Name='AutoHotkey.exe'") {
        try {
            cmdLine := process.CommandLine
            if InStr(cmdLine, A_ScriptName) && process.ProcessId != DllCall("GetCurrentProcessId") {
                MsgBox("Скрипт уже запущен!`nЗакройте предыдущую версию перед запуском новой.", "Anti-AFK", "Icon!")
                ExitApp
            }
        }
    }
}

AppName := "Anti-AFK Pro"
Version := "1.0.0"

; Настройки по умолчанию
Interval := 1000
DarkMode := true
Transparency := 255
IsTimerActive := false
TimeLeft := 1.0
KeyToPress := "w"
SendMethod := "Send"
Theme := "Dark"
AutoShutdownTime := 0
StartTime := 0
PressCount := 0
AntiDetect := false
AutoShutdownEnabled := false

; Статистика
Stats := Map()
Stats["TotalPresses"] := 0
Stats["TotalTime"] := 0
Stats["Sessions"] := 0

; Объявляем глобальные переменные для элементов GUI
global KeyDisplay, ProgressText, StatusText, StatsText, StartBtn, StopBtn, SettingsBtn, TitleText

MyGui := Gui()
ApplyTheme()

ApplyTheme() {
    global MyGui, Theme, TextColor, ButtonStyle, BgColor, ProgressBgColor
    
    if (Theme = "Dark") {
        BgColor := "0x1E1E1E"
        TextColor := "cWhite"
        ButtonStyle := "Background0x404040 cWhite"
        ProgressBgColor := "0x404040"
    } else if (Theme = "Blue") {
        BgColor := "0x1E3A5F"
        TextColor := "cWhite"
        ButtonStyle := "Background0x2E5A8F cWhite"
        ProgressBgColor := "0x2E5A8F"
    } else if (Theme = "Green") {
        BgColor := "0x2D4A32"
        TextColor := "cWhite"
        ButtonStyle := "Background0x3D5A42 cWhite"
        ProgressBgColor := "0x3D5A42"
    } else if (Theme = "Purple") {
        BgColor := "0x4A235A"
        TextColor := "cWhite"
        ButtonStyle := "Background0x5B336B cWhite"
        ProgressBgColor := "0x5B336B"
    } else if (Theme = "Red") {
        BgColor := "0x5A2323"
        TextColor := "cWhite"
        ButtonStyle := "Background0x6B3333 cWhite"
        ProgressBgColor := "0x6B3333"
    } else if (Theme = "Orange") {
        BgColor := "0x7D5A2D"
        TextColor := "cWhite"
        ButtonStyle := "Background0x8D6A3D cWhite"
        ProgressBgColor := "0x8D6A3D"
    } else if (Theme = "Cyber") {
        BgColor := "0x0A0A12"
        TextColor := "cLime"
        ButtonStyle := "Background0x00FF88 cBlack"
        ProgressBgColor := "0x00FF88"
    } else if (Theme = "Light") {
        BgColor := "0xFFFFFF"
        TextColor := "cBlack"  ; Чёрный текст для главного окна
        ButtonStyle := "Background0xE0E0E0 cBlack"
        ProgressBgColor := "0xE0E0E0"
    }
    
    if (MyGui.Hwnd) {
        MyGui.BackColor := BgColor
        ; Обновляем цвета элементов главного окна
        UpdateMainWindowColors()
    }
}

; Функция для обновления цветов главного окна
UpdateMainWindowColors() {
    global MyGui, TextColor, KeyDisplay, ProgressText, StatusText, StatsText, StartBtn, StopBtn, SettingsBtn, TitleText
    
    ; Проверяем, что элементы созданы, прежде чем обновлять их
    try {
        if (TitleText.Hwnd)
            TitleText.Opt(TextColor)
        if (KeyDisplay.Hwnd)
            KeyDisplay.Opt(TextColor)
        if (ProgressText.Hwnd)
            ProgressText.Opt(TextColor)
        if (StatusText.Hwnd)
            StatusText.Opt(TextColor)
        if (StatsText.Hwnd)
            StatsText.Opt(TextColor)
    }
}

UpdateGUI() {
    global MyGui, TextColor, ButtonStyle, BgColor
    MyGui.BackColor := BgColor
    UpdateMainWindowColors()
}

MyGui.Title := AppName " v" Version
MyGui.BackColor := BgColor
MyGui.SetFont("s9 Bold", "Segoe UI")

TitleText := MyGui.Add("Text", "x20 y20 w300 h30 " TextColor, "🕹️ Anti-AFK Pro")
MyGui.SetFont("s8 Norm", "Segoe UI")
KeyDisplay := MyGui.Add("Text", "x20 y45 w300 " TextColor, "Нажимает " KeyToPress " каждую секунду")

ProgressText := MyGui.Add("Text", "x20 y75 w300 " TextColor, "До следующего нажатия: 1.0s")
ProgressBar := MyGui.Add("Progress", "x20 y95 w310 h6 cGreen Background" ProgressBgColor " Smooth Range0-100", 100)

StatusText := MyGui.Add("Text", "x20 y115 w300 " TextColor, "● ОСТАНОВЛЕНО")

; Статистика
StatsText := MyGui.Add("Text", "x20 y140 w300 " TextColor, "Нажатий: 0 | Время: 0:00")

StartBtn := MyGui.Add("Button", "x20 y165 w90 h30 " ButtonStyle, "▶ Старт")
StopBtn := MyGui.Add("Button", "x120 y165 w90 h30 " ButtonStyle, "⏹ Стоп")
SettingsBtn := MyGui.Add("Button", "x220 y165 w90 h30 " ButtonStyle, "⚙ Настройки")

PressKey() {
    global TimeLeft, Interval, KeyToPress, SendMethod, PressCount, Stats, AntiDetect
    
    ; Анти-детект: случайная задержка
    actualInterval := Interval
    if (AntiDetect) {
        ; Случайное отклонение от -1000ms до +1000ms
        randomDeviation := Random(-1000, 1000)
        actualInterval := Interval + randomDeviation
        if (actualInterval < 500) ; Минимальный интервал 500ms
            actualInterval := 500
    }
    
    if (SendMethod = "Send") {
        Send("{" KeyToPress " down}")
        Sleep(30)
        Send("{" KeyToPress " up}")
    } else if (SendMethod = "SendInput") {
        SendInput("{" KeyToPress " down}")
        Sleep(30)
        SendInput("{" KeyToPress " up}")
    } else if (SendMethod = "SendEvent") {
        SendEvent("{" KeyToPress " down}")
        Sleep(30)
        SendEvent("{" KeyToPress " up}")
    }
    
    PressCount++
    Stats["TotalPresses"]++
    TimeLeft := actualInterval / 1000
    UpdateProgress()
    UpdateStats()
}

UpdateProgress() {
    global ProgressBar, ProgressText, TimeLeft, Interval
    ProgressBar.Value := (TimeLeft * 1000 / Interval) * 100
    ProgressText.Text := "До следующего нажатия: " Round(TimeLeft, 1) "s"
}

UpdateStats() {
    global StatsText, PressCount, StartTime, Stats
    
    if (StartTime > 0) {
        elapsed := A_TickCount - StartTime
        Stats["TotalTime"] := Stats["TotalTime"] + (elapsed // 1000)
        minutes := (elapsed // 60000)
        seconds := Mod((elapsed // 1000), 60)
        StatsText.Text := "Нажатий: " PressCount " | Время: " minutes ":" Format("{:02}", seconds)
    } else {
        StatsText.Text := "Нажатий: " PressCount " | Время: 0:00"
    }
}

SetTimer(MainTimer, 100)

MainTimer() {
    global TimeLeft, IsTimerActive, Interval, StartTime, AutoShutdownTime, AutoShutdownEnabled
    
    if (IsTimerActive) {
        TimeLeft -= 0.1
        if (TimeLeft <= 0) {
            PressKey()
        }
        UpdateProgress()
        UpdateStats()
        
        ; Проверка автоотключения
        if (AutoShutdownEnabled && AutoShutdownTime > 0 && StartTime > 0) {
            elapsed := A_TickCount - StartTime
            if (elapsed >= AutoShutdownTime * 60 * 1000) {
                StopAFK()
                TrayTip("Anti-AFK", "Автоотключение: прошло " AutoShutdownTime " минут", 1)
            }
        }
    }
}

StartAFK(*) {
    global IsTimerActive, StatusText, StartBtn, StopBtn, StartTime, PressCount, Stats
    
    if (!IsTimerActive) {
        IsTimerActive := true
        StartTime := A_TickCount
        PressCount := 0
        Stats["Sessions"]++
        StatusText.Text := "● АКТИВНО - " KeyToPress " каждую " (Interval/1000) "сек"
        StatusText.Opt("cLime")
        StartBtn.Enabled := false
        StopBtn.Enabled := true
    }
}

StopAFK(*) {
    global IsTimerActive, StatusText, StartBtn, StopBtn, TimeLeft, Interval, StartTime, Stats
    
    if (IsTimerActive) {
        IsTimerActive := false
        if (StartTime > 0) {
            elapsed := A_TickCount - StartTime
            Stats["TotalTime"] := Stats["TotalTime"] + (elapsed // 1000)
            StartTime := 0
        }
        StatusText.Text := "● ОСТАНОВЛЕНО"
        StatusText.Opt("cRed")
        StartBtn.Enabled := true
        StopBtn.Enabled := false
        TimeLeft := Interval / 1000
        UpdateProgress()
        UpdateStats()
    }
}

ShowSettings(*) {
    global Interval, Transparency, MyGui, KeyToPress, SendMethod, Theme, AutoShutdownTime, AntiDetect, AutoShutdownEnabled
    
    ; Сворачиваем основное окно
    MyGui.Hide()
    
    SettingsGui := Gui()
    SettingsGui.Title := "Настройки Anti-AFK"
    SettingsGui.BackColor := "0x1E1E1E"
    SettingsGui.SetFont("s9 cWhite", "Segoe UI")
    SettingsGui.MarginX := 20
    SettingsGui.MarginY := 15
    
    ; Основные настройки
    SettingsGui.SetFont("s11 Bold", "Segoe UI")
    MainSettingsTitle := SettingsGui.Add("Text", "x20 y20 w400 Section", "🔧 Основные настройки")
    MainSettingsTitle.Opt("cYellow")
    SettingsGui.SetFont("s9 Norm cWhite", "Segoe UI")
    
    ; Кнопка для нажатия
    SettingsGui.Add("Text", "xs y+15 w300", "Кнопка для нажатия:")
    KeyDropDown := SettingsGui.Add("DropDownList", "xs y+5 w120", ["w", "a", "s", "d", "Space", "Shift", "Ctrl", "Tab", "Enter"])
    KeyDropDown.Value := GetIndex(["w", "a", "s", "d", "Space", "Shift", "Ctrl", "Tab", "Enter"], KeyToPress)
    KeyInfoBtn := SettingsGui.Add("Button", "x+10 yp w30 h23 Background0x87CEEB cWhite", "ℹ")
    KeyInfoBtn.OnEvent("Click", (*) => ShowKeyInfo())
    
    ; Тип эмуляции
    SettingsGui.Add("Text", "xs y+15 w300", "Тип эмуляции:")
    SendMethodDropDown := SettingsGui.Add("DropDownList", "xs y+5 w120", ["Send", "SendInput", "SendEvent"])
    SendMethodDropDown.Value := GetIndex(["Send", "SendInput", "SendEvent"], SendMethod)
    SendMethodInfoBtn := SettingsGui.Add("Button", "x+10 yp w30 h23 Background0x87CEEB cWhite", "ℹ")
    SendMethodInfoBtn.OnEvent("Click", ShowSendModeInfo)
    
    ; Интервал нажатия
    SettingsGui.Add("Text", "xs y+15 w300", "Интервал нажатия (секунды):")
    IntervalEdit := SettingsGui.Add("Edit", "xs y+5 w120 BackgroundWhite cBlack Number", Interval/1000)
    IntervalEdit.Value := Interval/1000
    IntervalInfoBtn := SettingsGui.Add("Button", "x+10 yp w30 h23 Background0x87CEEB cWhite", "ℹ")
    IntervalInfoBtn.OnEvent("Click", (*) => ShowIntervalInfo())
    
    ; Раздел безопасности
    SettingsGui.SetFont("s11 Bold", "Segoe UI")
    SecurityTitle := SettingsGui.Add("Text", "xs y+25 w400 Section", "🛡️ Безопасность")
    SecurityTitle.Opt("cLime")
    SettingsGui.SetFont("s9 Norm cWhite", "Segoe UI")
    
    ; Анти-детект
    AntiDetectCheck := SettingsGui.Add("CheckBox", "xs y+10 Checked" AntiDetect, "Анти-детект режим")
    AntiDetectCheck.Value := AntiDetect
    AntiDetectInfoBtn := SettingsGui.Add("Button", "x+10 yp w30 h23 Background0x87CEEB cWhite", "ℹ")
    AntiDetectInfoBtn.OnEvent("Click", (*) => ShowAntiDetectInfo())
    
    ; Раздел умных функций
    SettingsGui.SetFont("s11 Bold", "Segoe UI")
    SmartFunctionsTitle := SettingsGui.Add("Text", "xs y+25 w400 Section", "🧠 Умные функции")
    SmartFunctionsTitle.Opt("cAqua")
    SettingsGui.SetFont("s9 Norm cWhite", "Segoe UI")
    
    ; Автоотключение - исправленная версия с правильным выравниванием
    AutoShutdownSection := SettingsGui.Add("Text", "xs y+10 w400") ; Невидимый контейнер для выравнивания
    
    AutoShutdownCheck := SettingsGui.Add("CheckBox", "xp yp w130 Checked" AutoShutdownEnabled, "Автоотключение")
    AutoShutdownCheck.Value := AutoShutdownEnabled
    
    ; Создаем элементы, которые будут показываться/скрываться
    AutoShutdownText := SettingsGui.Add("Text", "x+5 yp+3 w35 cWhite", "через:")
    AutoShutdownEdit := SettingsGui.Add("Edit", "x+5 yp-3 w50 BackgroundWhite cBlack Number", AutoShutdownTime)
    AutoShutdownEdit.Value := AutoShutdownTime
    AutoShutdownMinutesText := SettingsGui.Add("Text", "x+5 yp+3 w25 cWhite", "мин.")
    AutoShutdownInfoBtn := SettingsGui.Add("Button", "x+5 yp-3 w30 h23 Background0x87CEEB cWhite", "ℹ")
    AutoShutdownInfoBtn.OnEvent("Click", (*) => ShowAutoShutdownInfo())
    
    ; Функция для показа/скрытия элементов автоотключения
    ToggleAutoShutdownEdit(*) {
        AutoShutdownText.Visible := AutoShutdownCheck.Value
        AutoShutdownEdit.Visible := AutoShutdownCheck.Value
        AutoShutdownMinutesText.Visible := AutoShutdownCheck.Value
        AutoShutdownInfoBtn.Visible := AutoShutdownCheck.Value
    }
    
    AutoShutdownCheck.OnEvent("Click", ToggleAutoShutdownEdit)
    ToggleAutoShutdownEdit() ; Инициализация видимости
    
    ; Раздел персонализации
    SettingsGui.SetFont("s11 Bold", "Segoe UI")
    PersonalizationTitle := SettingsGui.Add("Text", "xs y+25 w400 Section", "🎨 Персонализация")
    PersonalizationTitle.Opt("cFuchsia")
    SettingsGui.SetFont("s9 Norm cWhite", "Segoe UI")
    
    ; Тема интерфейса
    SettingsGui.Add("Text", "xs y+10 w300", "Тема интерфейса:")
    ThemeDropDown := SettingsGui.Add("DropDownList", "xs y+5 w120", ["Dark", "Blue", "Green", "Purple", "Red", "Orange", "Cyber", "Light"])
    ThemeDropDown.Value := GetIndex(["Dark", "Blue", "Green", "Purple", "Red", "Orange", "Cyber", "Light"], Theme)
    ThemeInfoBtn := SettingsGui.Add("Button", "x+10 yp w30 h23 Background0x87CEEB cWhite", "ℹ")
    ThemeInfoBtn.OnEvent("Click", (*) => ShowThemeInfo())
    
    ; Прозрачность
    SettingsGui.Add("Text", "xs y+15 w300", "Прозрачность окна (%):")
    TransparencySlider := SettingsGui.Add("Slider", "xs y+5 w120 Range20-100 ToolTip", Round(Transparency/255*100))
    TransparencyValue := SettingsGui.Add("Text", "x+10 yp w40 cWhite", Round(Transparency/255*100) "%")
    TransparencySlider.OnEvent("Change", (*) => TransparencyValue.Text := TransparencySlider.Value "%")
    TransparencyInfoBtn := SettingsGui.Add("Button", "x+10 yp w30 h23 Background0x87CEEB cWhite", "ℹ")
    TransparencyInfoBtn.OnEvent("Click", (*) => ShowTransparencyInfo())
    
    ; Примечание внизу
    SettingsGui.SetFont("s9 Bold", "Segoe UI")
    NoteText := SettingsGui.Add("Text", "xs y+30 w400 Center", "💡 Функций в дальнейшем будет больше!")
    NoteText.Opt("cSilver")
    
    ; Кнопки применения/отмены
    ApplyBtn := SettingsGui.Add("Button", "xs y+20 w80 Background0x404040 cWhite", "Применить")
    CancelBtn := SettingsGui.Add("Button", "x+20 yp w80 Background0x404040 cWhite", "Отмена")
    
    ApplyBtn.OnEvent("Click", ApplySettings)
    CancelBtn.OnEvent("Click", CancelSettings)
    
    ; Обработчик закрытия настроек
    SettingsGui.OnEvent("Close", CancelSettings)
    SettingsGui.OnEvent("Escape", CancelSettings)
    
    ApplySettings(*) {
        global Interval, Transparency, IsTimerActive, TimeLeft, KeyToPress, SendMethod, Theme, AutoShutdownTime, AntiDetect, AutoShutdownEnabled
        
        ; Проверяем, что введено число
        if IntervalEdit.Value = "" or not IsNumber(IntervalEdit.Value) {
            MsgBox("Введите корректное число для интервала!", "Ошибка", "Icon!")
            return
        }
        
        KeyToPress := KeyDropDown.Text
        SendMethod := SendMethodDropDown.Text
        Interval := IntervalEdit.Value * 1000
        Transparency := Round(TransparencySlider.Value * 2.55)
        Theme := ThemeDropDown.Text
        AutoShutdownEnabled := AutoShutdownCheck.Value
        AutoShutdownTime := AutoShutdownEdit.Value
        AntiDetect := AntiDetectCheck.Value
        
        ; Применяем настройки
        WinSetTransparent(Transparency, MyGui)
        ApplyTheme()
        UpdateGUI()
        KeyDisplay.Text := "Нажимает " KeyToPress " каждую " (Interval/1000) " секунду"
        
        if (IsTimerActive) {
            TimeLeft := Interval / 1000
            StatusText.Text := "● АКТИВНО - " KeyToPress " каждую " (Interval/1000) "сек"
            UpdateProgress()
        } else {
            TimeLeft := Interval / 1000
            UpdateProgress()
        }
        
        SettingsGui.Destroy()
        MyGui.Show()
        TrayTip("Anti-AFK", "Настройки применены!", 1)
    }
    
    CancelSettings(*) {
        SettingsGui.Destroy()
        MyGui.Show()
    }
    
    SettingsGui.Show()
}

; Функции для показа информации о параметрах (остаются без изменений)
ShowKeyInfo() {
    InfoGui := Gui()
    InfoGui.Title := "Кнопка для нажатия"
    InfoGui.BackColor := "0x1E1E1E"
    InfoGui.MarginX := 20
    InfoGui.MarginY := 15
    
    InfoGui.SetFont("s10 Bold cWhite", "Segoe UI")
    InfoGui.Add("Text", "w400 Center", "🎮 Кнопка для нажатия")
    
    InfoGui.SetFont("s9 Norm cWhite", "Segoe UI")
    InfoGui.Add("Text", "w400", " ")
    InfoGui.Add("Text", "w400", "Выберите клавишу, которую будет нажимать скрипт.")
    InfoGui.Add("Text", "w400 cGray", "• W, A, S, D - стандартные клавиши движения`n• Space - пробел`n• Shift, Ctrl - модификаторы`n• Tab, Enter - специальные клавиши")
    
    CloseBtn := InfoGui.Add("Button", "w100 Center Background0x404040 cWhite", "Закрыть")
    CloseBtn.OnEvent("Click", (*) => InfoGui.Destroy())
    InfoGui.OnEvent("Close", (*) => InfoGui.Destroy())
    InfoGui.OnEvent("Escape", (*) => InfoGui.Destroy())
    InfoGui.Show()
}

ShowIntervalInfo() {
    InfoGui := Gui()
    InfoGui.Title := "Интервал нажатия"
    InfoGui.BackColor := "0x1E1E1E"
    InfoGui.MarginX := 20
    InfoGui.MarginY := 15
    
    InfoGui.SetFont("s10 Bold cWhite", "Segoe UI")
    InfoGui.Add("Text", "w400 Center", "⏱️ Интервал нажатия")
    
    InfoGui.SetFont("s9 Norm cWhite", "Segoe UI")
    InfoGui.Add("Text", "w400", " ")
    InfoGui.Add("Text", "w400", "Интервал между нажатиями клавиши в секундах.")
    InfoGui.Add("Text", "w400 cGray", "• 1.0 = 1 секунда`n• 0.5 = 500 миллисекунд`n• 2.0 = 2 секунды`n• Рекомендуется: 1.0-5.0 секунд")
    
    CloseBtn := InfoGui.Add("Button", "w100 Center Background0x404040 cWhite", "Закрыть")
    CloseBtn.OnEvent("Click", (*) => InfoGui.Destroy())
    InfoGui.OnEvent("Close", (*) => InfoGui.Destroy())
    InfoGui.OnEvent("Escape", (*) => InfoGui.Destroy())
    InfoGui.Show()
}

ShowAntiDetectInfo() {
    InfoGui := Gui()
    InfoGui.Title := "Анти-детект режим"
    InfoGui.BackColor := "0x1E1E1E"
    InfoGui.MarginX := 20
    InfoGui.MarginY := 15
    
    InfoGui.SetFont("s10 Bold cWhite", "Segoe UI")
    InfoGui.Add("Text", "w400 Center", "🛡️ Анти-детект режим")
    
    InfoGui.SetFont("s9 Norm cWhite", "Segoe UI")
    InfoGui.Add("Text", "w400", " ")
    InfoGui.Add("Text", "w400", "Добавляет случайные отклонения к интервалу нажатий.")
    InfoGui.Add("Text", "w400 cGray", "✓ Случайные задержки от -1 до +1 секунды`n✓ Меньше похоже на бота`n✓ Сложнее обнаружить`n⚠️ Менее предсказуемое поведение")
    
    CloseBtn := InfoGui.Add("Button", "w100 Center Background0x404040 cWhite", "Закрыть")
    CloseBtn.OnEvent("Click", (*) => InfoGui.Destroy())
    InfoGui.OnEvent("Close", (*) => InfoGui.Destroy())
    InfoGui.OnEvent("Escape", (*) => InfoGui.Destroy())
    InfoGui.Show()
}

ShowAutoShutdownInfo() {
    InfoGui := Gui()
    InfoGui.Title := "Автоотключение"
    InfoGui.BackColor := "0x1E1E1E"
    InfoGui.MarginX := 20
    InfoGui.MarginY := 15
    
    InfoGui.SetFont("s10 Bold cWhite", "Segoe UI")
    InfoGui.Add("Text", "w400 Center", "⏰ Автоотключение")
    
    InfoGui.SetFont("s9 Norm cWhite", "Segoe UI")
    InfoGui.Add("Text", "w400", " ")
    InfoGui.Add("Text", "w400", "Автоматическое отключение скрипта через указанное время.")
    InfoGui.Add("Text", "w400 cGray", "• 0 = функция выключена`n• 30 = отключится через 30 минут`n• 60 = отключится через 1 час`n• Полезно для безопасности")
    
    CloseBtn := InfoGui.Add("Button", "w100 Center Background0x404040 cWhite", "Закрыть")
    CloseBtn.OnEvent("Click", (*) => InfoGui.Destroy())
    InfoGui.OnEvent("Close", (*) => InfoGui.Destroy())
    InfoGui.OnEvent("Escape", (*) => InfoGui.Destroy())
    InfoGui.Show()
}

ShowThemeInfo() {
    InfoGui := Gui()
    InfoGui.Title := "Темы интерфейса"
    InfoGui.BackColor := "0x1E1E1E"
    InfoGui.MarginX := 20
    InfoGui.MarginY := 15
    
    InfoGui.SetFont("s10 Bold cWhite", "Segoe UI")
    InfoGui.Add("Text", "w400 Center", "🎨 Темы интерфейса")
    
    InfoGui.SetFont("s9 Norm cWhite", "Segoe UI")
    InfoGui.Add("Text", "w400", " ")
    InfoGui.Add("Text", "w400", "Выберите цветовую схему интерфейса.")
    InfoGui.Add("Text", "w400 cGray", "• Dark - тёмная тема`n• Light - светлая тема`n• Blue, Green, Purple - цветные темы`n• Cyber - неоновая зелёная`n• Red, Orange - тёплые темы")
    
    CloseBtn := InfoGui.Add("Button", "w100 Center Background0x404040 cWhite", "Закрыть")
    CloseBtn.OnEvent("Click", (*) => InfoGui.Destroy())
    InfoGui.OnEvent("Close", (*) => InfoGui.Destroy())
    InfoGui.OnEvent("Escape", (*) => InfoGui.Destroy())
    InfoGui.Show()
}

ShowTransparencyInfo() {
    InfoGui := Gui()
    InfoGui.Title := "Прозрачность окна"
    InfoGui.BackColor := "0x1E1E1E"
    InfoGui.MarginX := 20
    InfoGui.MarginY := 15
    
    InfoGui.SetFont("s10 Bold cWhite", "Segoe UI")
    InfoGui.Add("Text", "w400 Center", "🔍 Прозрачность окна")
    
    InfoGui.SetFont("s9 Norm cWhite", "Segoe UI")
    InfoGui.Add("Text", "w400", " ")
    InfoGui.Add("Text", "w400", "Настройка прозрачности основного окна скрипта.")
    InfoGui.Add("Text", "w400 cGray", "• 100% = полностью непрозрачное`n• 50% = полупрозрачное`n• 20% = почти прозрачное`n• Полезно для поверх других окон")
    
    CloseBtn := InfoGui.Add("Button", "w100 Center Background0x404040 cWhite", "Закрыть")
    CloseBtn.OnEvent("Click", (*) => InfoGui.Destroy())
    InfoGui.OnEvent("Close", (*) => InfoGui.Destroy())
    InfoGui.OnEvent("Escape", (*) => InfoGui.Destroy())
    InfoGui.Show()
}

; Функция для показа информации о типах эмуляции
ShowSendModeInfo(*) {
    InfoGui := Gui()
    InfoGui.Title := "Типы эмуляции клавиш"
    InfoGui.BackColor := "0x1E1E1E"
    InfoGui.MarginX := 20
    InfoGui.MarginY := 15
    
    ; Заголовок
    InfoGui.SetFont("s10 Bold cWhite", "Segoe UI")
    InfoGui.Add("Text", "w400 Center", "📋 Типы эмуляции клавиш")
    
    InfoGui.SetFont("s9 Norm cWhite", "Segoe UI")
    InfoGui.Add("Text", "w400", " ")
    
    ; Send
    InfoGui.SetFont("s9 Bold cLime", "Segoe UI")
    InfoGui.Add("Text", "w400 Section", "• Send")
    InfoGui.SetFont("s9 Norm cWhite", "Segoe UI")
    InfoGui.Add("Text", "w400", "Стандартный метод, работает в большинстве случаев")
    InfoGui.Add("Text", "w400 cGray", "✓ Универсальный`n⏱️ Средняя скорость`n🛡️ Хорошая совместимость")
    InfoGui.Add("Text", "w400", " ")
    
    ; SendInput
    InfoGui.SetFont("s9 Bold cYellow", "Segoe UI")
    InfoGui.Add("Text", "w400 Section", "• SendInput")
    InfoGui.SetFont("s9 Norm cWhite", "Segoe UI")
    InfoGui.Add("Text", "w400", "Самый быстрый метод, но может не работать в играх")
    InfoGui.Add("Text", "w400 cGray", "⚡ Максимальная скорость`n🎯 Точное время`n⚠️ Может не работать в играми")
    InfoGui.Add("Text", "w400", " ")
    
    ; SendEvent
    InfoGui.SetFont("s9 Bold cAqua", "Segoe UI")
    InfoGui.Add("Text", "w400 Section", "• SendEvent")
    InfoGui.SetFont("s9 Norm cWhite", "Segoe UI")
    InfoGui.Add("Text", "w400", "Рекомендуется для игр, баланс скорости и совместимости")
    InfoGui.Add("Text", "w400 cGray", "🎮 Лучшая совместимость с играми`n⚡ Высокая скорость`n🛡️ Надежный")
    InfoGui.Add("Text", "w400", " ")
    
    InfoGui.SetFont("s9 Bold cSilver", "Segoe UI")
    InfoGui.Add("Text", "w400 Center", "💡 Рекомендация: Начните с SendEvent для игр")
    
    CloseBtn := InfoGui.Add("Button", "w100 Center Background0x404040 cWhite", "Закрыть")
    CloseBtn.OnEvent("Click", (*) => InfoGui.Destroy())
    
    InfoGui.OnEvent("Close", (*) => InfoGui.Destroy())
    InfoGui.OnEvent("Escape", (*) => InfoGui.Destroy())
    
    InfoGui.Show()
}

; Функция для получения индекса в списке
GetIndex(list, value) {
    for index, item in list {
        if (item = value) {
            return index
        }
    }
    return 1
}

StartBtn.OnEvent("Click", StartAFK)
StopBtn.OnEvent("Click", StopAFK)
SettingsBtn.OnEvent("Click", ShowSettings)

F1::StartAFK()
F2::StopAFK()

MyGui.OnEvent("Close", (*) => ExitApp())
MyGui.OnEvent("Escape", (*) => ExitApp())

A_TrayMenu.Delete()
A_TrayMenu.Add("Открыть", (*) => MyGui.Show())
A_TrayMenu.Add("Старт", StartAFK)
A_TrayMenu.Add("Стоп", StopAFK)
A_TrayMenu.Add("Настройки", ShowSettings)
A_TrayMenu.Add()
A_TrayMenu.Add("Выход", (*) => ExitApp())

MyGui.Show()
StopBtn.Enabled := false
UpdateProgress()
UpdateStats()