import AppKit

final class Launcher: NSObject, NSApplicationDelegate {
    let russian = Locale.preferredLanguages.first?.hasPrefix("ru") == true
    var window: NSWindow!
    let source = NSTextField(string: "/Applications/CrossOver.app")
    let bottles = NSPopUpButton(frame: .zero, pullsDown: false)
    let output = NSTextView()
    let action = NSButton()
    let hud = NSButton(checkboxWithTitle: "Metal HUD", target: nil, action: nil)
    let diagnostics = NSButton(checkboxWithTitle: "Diagnostic log", target: nil, action: nil)
    var active: Process?
    func t(_ en: String, _ ru: String) -> String { russian ? ru : en }
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        window = NSWindow(contentRect: NSRect(x: 0,y: 0,width: 740,height: 570),styleMask: [.titled,.closable,.miniaturizable],backing: .buffered,defer: false)
        window.title = "X4 Launcher"
        window.center()
        let root = NSStackView(); root.orientation = .vertical; root.alignment = .leading; root.spacing = 12
        root.edgeInsets = NSEdgeInsets(top: 22,left: 24,bottom: 22,right: 24)
        window.contentView = root
        let title = NSTextField(labelWithString: t("X4 on your Mac", "X4 на твоём Mac"))
        title.font = .boldSystemFont(ofSize: 28); root.addArrangedSubview(title)
        let intro = NSTextField(wrappingLabelWithString: t("Install the graphics fix and launch your Steam copy of X4. You need CrossOver 26.2 and an installed game in a 64 bit bottle.", "Установить графическое исправление и запустить X4 из Steam. Нужны CrossOver 26.2 и установленная игра в 64 битной бутылке."))
        root.addArrangedSubview(intro)
        let pathRow = NSStackView(); pathRow.spacing = 8
        pathRow.addArrangedSubview(NSTextField(labelWithString: "CrossOver:")); pathRow.addArrangedSubview(source)
        let browse = NSButton(title: t("Choose…", "Выбрать…"),target: self,action: #selector(chooseSource)); pathRow.addArrangedSubview(browse)
        root.addArrangedSubview(pathRow)
        let bottleRoot = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/CrossOver/Bottles")
        var preferred: String?
        if let dirs = try? FileManager.default.contentsOfDirectory(at: bottleRoot,includingPropertiesForKeys: nil) {
            for dir in dirs.sorted(by: {$0.lastPathComponent < $1.lastPathComponent}) {
                let steam = dir.appendingPathComponent("drive_c/Program Files (x86)/Steam")
                if FileManager.default.fileExists(atPath: steam.appendingPathComponent("steam.exe").path) {
                    bottles.addItem(withTitle: dir.lastPathComponent)
                    if FileManager.default.fileExists(atPath: steam.appendingPathComponent("steamapps/appmanifest_392160.acf").path) { preferred = dir.lastPathComponent }
                }
            }
        }
        if let preferred = preferred { bottles.selectItem(withTitle: preferred) }
        if bottles.numberOfItems == 0 { bottles.addItem(withTitle: t("Install Windows Steam in CrossOver first", "Сначала установите Windows Steam в CrossOver")); bottles.isEnabled = false }
        let bottleRow = NSStackView(); bottleRow.spacing = 8
        bottleRow.addArrangedSubview(NSTextField(labelWithString: t("Steam bottle:", "Бутылка Steam:"))); bottleRow.addArrangedSubview(bottles); root.addArrangedSubview(bottleRow)
        let options = NSStackView(); options.spacing = 20
        diagnostics.title = t("Diagnostic log", "Журнал диагностики")
        options.addArrangedSubview(hud); options.addArrangedSubview(diagnostics); root.addArrangedSubview(options)
        let note = NSTextField(wrappingLabelWithString: t("The fix downloads MoltenVK from Khronos, checks its checksum and signs a separate CrossOver copy locally. The original app is preserved. Your existing Steam bottle and saves are shared. Windows Steam may close to switch runtime. Save other games before continuing.", "Исправление скачает MoltenVK от Khronos, проверит контрольную сумму и подпишет отдельную копию CrossOver. Исходное приложение сохранится. Бутылка Steam и сохранения будут общими. Windows Steam может закрыться для смены библиотеки. Перед продолжением сохраните другие игры."))
        note.font = .systemFont(ofSize: 12); note.textColor = .secondaryLabelColor; root.addArrangedSubview(note)
        action.title = t("Install and launch", "Установить и запустить"); action.target = self; action.action = #selector(play); action.bezelStyle = .rounded; action.keyEquivalent = "\r"
        root.addArrangedSubview(action)
        let scroll = NSScrollView(); scroll.hasVerticalScroller = true; scroll.borderType = .bezelBorder
        output.isEditable = false; output.font = .monospacedSystemFont(ofSize: 11,weight: .regular)
        output.autoresizingMask = [.width]; output.isVerticallyResizable = true
        output.textContainer?.widthTracksTextView = true; scroll.documentView = output
        root.addArrangedSubview(scroll)
        for view in [intro,pathRow,bottleRow,note,scroll] { view.widthAnchor.constraint(equalTo: root.widthAnchor,constant: -48).isActive = true }
        scroll.heightAnchor.constraint(greaterThanOrEqualToConstant: 140).isActive = true
        window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
    }
    @objc func chooseSource() {
        let panel=NSOpenPanel(); panel.canChooseDirectories=false;panel.canChooseFiles=true;panel.allowedFileTypes=["app"]
        if panel.runModal() == .OK, let url=panel.url { source.stringValue=url.path }
    }
    func append(_ text: String) {
        DispatchQueue.main.async { self.output.textStorage?.append(NSAttributedString(string:text));self.output.scrollToEndOfDocument(nil) }
    }
    @objc func play() {
        guard active == nil else { return }
        guard bottles.isEnabled, let bottle = bottles.selectedItem?.title else {
            append(t("Install Windows Steam and X4 in CrossOver first.\n", "Сначала установите Windows Steam и X4 в CrossOver.\n")); return
        }
        guard let resources=Bundle.main.resourceURL else { return }
        let process=Process(); process.executableURL=URL(fileURLWithPath:"/bin/bash")
        var args=[resources.appendingPathComponent("scripts/play.sh").path,"--source-app",source.stringValue,"--bottle",bottle]
        if hud.state == .on { args.append("--metal-hud") }
        if diagnostics.state == .on { args.append("--diagnostic") }
        process.arguments=args
        let pipe=Pipe(); process.standardOutput=pipe;process.standardError=pipe
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data=handle.availableData
            if !data.isEmpty { self.append(String(decoding:data,as:UTF8.self)) }
        }
        process.terminationHandler = { task in
            pipe.fileHandleForReading.readabilityHandler=nil
            let remaining=pipe.fileHandleForReading.availableData
            if !remaining.isEmpty { self.append(String(decoding:remaining,as:UTF8.self)) }
            DispatchQueue.main.async {
                self.active=nil; self.action.isEnabled=true;self.source.isEnabled=true;self.bottles.isEnabled=true
                self.append(task.terminationStatus == 0 ? self.t("\nDone. Steam may need a moment to open the game.\n", "\nГотово. Steam может потребоваться немного времени для запуска игры.\n") : self.t("\nCould not complete. See the message above.\n", "\nНе удалось завершить. Причина указана выше.\n"))
            }
        }
        do { try process.run();active=process;action.isEnabled=false;source.isEnabled=false;bottles.isEnabled=false }
        catch { append(error.localizedDescription+"\n") }
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { active == nil }
}
if CommandLine.arguments.contains("--self-test") {
    guard let resource = Bundle.main.resourceURL else { exit(1) }
    for name in ["play.sh", "install.sh", "launch.sh", "common.sh", "doctor.sh", "uninstall.sh"] {
        guard FileManager.default.fileExists(atPath: resource.appendingPathComponent("scripts/" + name).path) else { exit(2) }
    }
    print("Launcher resources verified")
    exit(0)
}
let app=NSApplication.shared
let delegate=Launcher()
app.delegate=delegate
app.run()
