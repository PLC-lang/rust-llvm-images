ARG WINDOWS_VERSION=ltsc2022
ARG BASE_IMAGE=mcr.microsoft.com/windows/servercore:$WINDOWS_VERSION

FROM $BASE_IMAGE

ARG LLVM_VER=21.1.7
ARG RUST_VER=1.90
ARG ZIP_VERSION=2501
ARG GIT_VERSION=2.56.0
# Git for Windows build number (vX.Y.Z.windows.N); .3+ drops the eMudhra roots from its CA bundle
ARG GIT_WINDOWS_RELEASE=4

WORKDIR C:/buildtools

# Install VC++
# Download channel for fixed install.
ARG CHANNEL_URL=https://aka.ms/vs/17/release/channel
ADD ${CHANNEL_URL} C:/TEMP/VisualStudio.chman

# Download and install Build Tools for Visual Studio 2022 for native desktop workload.
ADD https://aka.ms/vs/17/release/vs_buildtools.exe C:/TEMP/vs_buildtools.exe
RUN C:/TEMP/vs_buildtools.exe --quiet --wait --norestart --nocache \
    --channelUri C:/TEMP/VisualStudio.chman \
    --installChannelUri C:/TEMP/VisualStudio.chman \
    --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended \
    --installPath C:/buildtools

ADD https://www.7-zip.org/a/7z${ZIP_VERSION}-x64.exe 7zsetup.exe
#Install 7zip
RUN 7zsetup.exe /S /D=C:/buildtools/7z

RUN setx /M PATH "%PATH%;C:\\buildtools\\7z;C:\\buildtools\\llvm\\bin"

ADD https://github.com/git-for-windows/git/releases/download/v${GIT_VERSION}.windows.${GIT_WINDOWS_RELEASE}/PortableGit-${GIT_VERSION}.${GIT_WINDOWS_RELEASE}-64-bit.7z.exe C:/TEMP/git-install.exe
# Install git to use bash
RUN 7z.exe x C:/TEMP/git-install.exe -ogit

ADD https://github.com/ghaith/llvm-package-windows/releases/download/v${LLVM_VER}/LLVM-${LLVM_VER}-win64.7z C:/TEMP/llvm.7z
# Setup llvm sources
RUN 7z x C:/TEMP/llvm.7z -ollvm 

ADD https://win.rustup.rs C:/TEMP/rustup-init.exe
# Install Rust
# RUN scoop install rustup
ADD https://win.rustup.rs C:/TEMP/rustup-init.exe
RUN C:/TEMP/rustup-init.exe --default-toolchain %RUST_VER% -y
RUN rustup install stable

RUN rustup component add llvm-tools-preview 
# Pinned to the newest releases that still build with Rust 1.90
RUN cargo install --locked mdbook@0.5.4 grcov@0.10.7

# cargo-nextest 0.9.129+ needs Rust 1.91 to build, and 0.9.128 embeds the distrusted
# emSign ECC Root CA - G3, so use the prebuilt release binary instead
ARG NEXTEST_VERSION=0.9.149
ADD https://github.com/nextest-rs/nextest/releases/download/cargo-nextest-${NEXTEST_VERSION}/cargo-nextest-${NEXTEST_VERSION}-x86_64-pc-windows-msvc.zip C:/TEMP/nextest.zip
RUN 7z x C:/TEMP/nextest.zip -o%USERPROFILE%\.cargo\bin && del /q C:\TEMP\nextest.zip

#RUN cargo install cargo-watch #Activate this for local builds to enable watching
WORKDIR C:/build

SHELL ["C:\\buildtools\\Common7\\Tools\\VsDevCmd.bat", "&&", "powershell.exe", "-NoLogo", "-ExecutionPolicy", "Bypass"]

#ENTRYPOINT ["cargo"]
ENTRYPOINT ["C:\\buildtools\\Common7\\Tools\\VsDevCmd.bat", "&&", "C:\\buildtools\\git\\bin\\bash.exe", "-i", "-l"]

