#include <windows.h>
#include <cstdint>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <string>

namespace fs = std::filesystem;
static const char marker[] = "HADES_TOOLS_PAYLOAD_V1\n";

static std::wstring quote(const std::wstring &value) {
    std::wstring out = L"\"";
    for (wchar_t c : value) {
        if (c == L'\"') out += L"\\\"";
        else out += c;
    }
    out += L"\"";
    return out;
}

int WINAPI wWinMain(HINSTANCE, HINSTANCE, PWSTR, int) {
    wchar_t selfBuffer[MAX_PATH * 4]{};
    const DWORD selfLength = GetModuleFileNameW(nullptr, selfBuffer, static_cast<DWORD>(std::size(selfBuffer)));
    if (!selfLength || selfLength >= std::size(selfBuffer)) return 2;

    std::ifstream self(fs::path(selfBuffer), std::ios::binary);
    if (!self) return 3;
    self.seekg(0, std::ios::end);
    const auto fileSize = self.tellg();
    const auto markerSize = static_cast<std::streamoff>(sizeof(marker) - 1);
    const auto footerSize = markerSize + static_cast<std::streamoff>(sizeof(std::uint64_t));
    if (fileSize <= footerSize) return 4;
    self.seekg(fileSize - markerSize);
    std::string tail(static_cast<size_t>(markerSize), '\0');
    self.read(tail.data(), markerSize);
    if (tail != marker) return 5;

    std::uint64_t payloadLength = 0;
    self.seekg(fileSize - footerSize);
    self.read(reinterpret_cast<char *>(&payloadLength), sizeof(payloadLength));
    if (!self || payloadLength == 0) return 5;

    const auto payloadOffset = fileSize - footerSize - static_cast<std::streamoff>(payloadLength);
    if (payloadOffset < 0) return 5;
    self.seekg(payloadOffset);
    std::string payload(static_cast<size_t>(payloadLength), '\0');
    self.read(payload.data(), static_cast<std::streamsize>(payloadLength));
    if (!self) return 5;

    wchar_t tempBuffer[MAX_PATH]{};
    if (!GetTempPathW(MAX_PATH, tempBuffer)) return 6;
    const std::wstring root = std::wstring(tempBuffer) + L"HadesTools-v0.2.6-" + std::to_wstring(GetCurrentProcessId());
    fs::create_directories(root);
    const fs::path zip = fs::path(root) / L"payload.zip";
    std::ofstream out(zip, std::ios::binary);
    out.write(payload.data(), static_cast<std::streamsize>(payload.size()));
    out.close();

    const fs::path expanded = fs::path(root) / L"expanded";
    fs::create_directories(expanded);
    const std::wstring command = L"-NoProfile -ExecutionPolicy Bypass -Command \"Expand-Archive -LiteralPath " +
        quote(zip.wstring()) + L" -DestinationPath " + quote(expanded.wstring()) + L" -Force\"";
    STARTUPINFOW startup{sizeof(startup)};
    PROCESS_INFORMATION process{};
    std::wstring powershell = L"powershell.exe " + command;
    if (!CreateProcessW(nullptr, powershell.data(), nullptr, nullptr, FALSE, CREATE_NO_WINDOW, nullptr, nullptr, &startup, &process)) return 7;
    WaitForSingleObject(process.hProcess, INFINITE);
    DWORD expandExit = 1;
    GetExitCodeProcess(process.hProcess, &expandExit);
    CloseHandle(process.hThread);
    CloseHandle(process.hProcess);
    if (expandExit != 0) return 8;

    const fs::path app = expanded / L"HadesTools-v0.2.6" / L"HadesTools.exe";
    if (!fs::exists(app)) return 9;
    SetCurrentDirectoryW(app.parent_path().c_str());
    std::wstring appCommand = quote(app.wstring());
    if (!CreateProcessW(app.c_str(), appCommand.data(), nullptr, nullptr, FALSE, 0, nullptr,
                        app.parent_path().c_str(), &startup, &process)) return 10;
    CloseHandle(process.hThread);
    CloseHandle(process.hProcess);
    return 0;
}
