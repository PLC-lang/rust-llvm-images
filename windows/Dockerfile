# escape=`
ARG WINDOWS_VERSION=ltsc2022
ARG BASE_IMAGE=mcr.microsoft.com/windows/servercore:$WINDOWS_VERSION

FROM $BASE_IMAGE

ARG LLVM_VERSION=21.1.7
ARG RUST_VERSION=1.93.1
ARG 7ZIP_VERSION=2600
ARG GIT_VERSION=2.53.0

WORKDIR C:/buildtools

# ==============================================================================
# STAGE 1: Install VS Build Tools (fail fast if VS installer is broken)
# ==============================================================================
ARG CHANNEL_URL=https://aka.ms/vs/17/release/channel
ADD ${CHANNEL_URL} C:/TEMP/VisualStudio.chman

ADD https://aka.ms/vs/17/release/vs_buildtools.exe C:/TEMP/vs_buildtools.exe
RUN C:/TEMP/vs_buildtools.exe --quiet --wait --norestart --nocache `
    --channelUri C:/TEMP/VisualStudio.chman `
    --installChannelUri C:/TEMP/VisualStudio.chman `
    --installPath C:/buildtools `
    --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended `
    && del /q C:\TEMP\vs_buildtools.exe C:\TEMP\VisualStudio.chman

# ==============================================================================
# STAGE 2: Install Rust and tools (fail fast if MSVC toolchain broken)
# This validates that VS + Windows SDK are correctly installed and can compile
# ==============================================================================
SHELL ["C:\\buildtools\\Common7\\Tools\\VsDevCmd.bat", "&&", "cmd", "/S", "/C"]

ADD https://win.rustup.rs C:/TEMP/rustup-init.exe
RUN C:/TEMP/rustup-init.exe --default-toolchain %RUST_VERSION% -y `
    && del /q C:\TEMP\rustup-init.exe

# Set PATH for Rust - VsDevCmd.bat already sets up MSVC paths
RUN setx /M PATH "%PATH%;%USERPROFILE%\.cargo\bin"

# Install cargo-binstall first, then use it to download pre-built binaries
# This is faster and avoids hcsshim layer issues with large compile artifacts
ADD https://github.com/cargo-bins/cargo-binstall/releases/latest/download/cargo-binstall-x86_64-pc-windows-msvc.zip C:/TEMP/binstall.zip
RUN powershell -Command "Expand-Archive -Path C:\TEMP\binstall.zip -DestinationPath C:\TEMP\binstall" `
    && copy C:\TEMP\binstall\cargo-binstall.exe %USERPROFILE%\.cargo\bin\ `
    && del /q C:\TEMP\binstall.zip `
    && rmdir /s /q C:\TEMP\binstall

# Install tools via binstall (pre-built binaries, no compilation)
# Falls back to cargo install if no binary available
RUN cargo binstall --no-confirm cargo-nextest grcov mdbook `
    && rmdir /s /q %USERPROFILE%\.cargo\registry 2>nul || echo "No registry to clean"

RUN rustup component add llvm-tools-preview

# ==============================================================================
# STAGE 3: Install additional tools (7zip, git, LLVM)
# These are slower downloads/extractions but don't affect build validation
# ==============================================================================
ADD https://www.7-zip.org/a/7z${7ZIP_VERSION}-x64.exe C:/TEMP/7zsetup.exe
RUN C:/TEMP/7zsetup.exe /S /D=C:\buildtools\7z `
    && del /q C:\TEMP\7zsetup.exe

RUN setx /M PATH "%PATH%;C:\buildtools\7z;C:\buildtools\llvm\bin;C:\buildtools\git\bin"

ADD https://github.com/git-for-windows/git/releases/download/v${GIT_VERSION}.windows.1/PortableGit-${GIT_VERSION}-64-bit.7z.exe C:/TEMP/git-install.exe
RUN C:\buildtools\7z\7z.exe x C:/TEMP/git-install.exe -ogit `
    && del /q C:\TEMP\git-install.exe

ADD https://github.com/ghaith/llvm-package-windows/releases/download/v${LLVM_VERSION}/LLVM-${LLVM_VERSION}-win64.7z C:/TEMP/llvm.7z
RUN C:\buildtools\7z\7z.exe x C:/TEMP/llvm.7z -ollvm `
    && del /q C:\TEMP\llvm.7z

# ==============================================================================
# Final setup
# ==============================================================================
WORKDIR C:/build

SHELL ["C:\\buildtools\\Common7\\Tools\\VsDevCmd.bat", "&&", "powershell.exe", "-NoLogo", "-ExecutionPolicy", "Bypass"]

ENTRYPOINT ["C:\\buildtools\\Common7\\Tools\\VsDevCmd.bat", "&&", "C:\\buildtools\\git\\bin\\bash.exe", "-i", "-l"]
