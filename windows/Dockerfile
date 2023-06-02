ARG WINDOWS_VERSION=ltsc2022
ARG BASE_IMAGE=mcr.microsoft.com/windows/servercore:$WINDOWS_VERSION

FROM $BASE_IMAGE

ARG LLVM_VER=14.0.6
ARG RUST_VER=1.70.0
ARG 7ZIP_VERSION=2201
ARG GIT_VERSION=2.39.1

# Install VC++

WORKDIR C:/buildtools

# Download channel for fixed install.
ARG CHANNEL_URL=https://aka.ms/vs/17/release/channel
ADD ${CHANNEL_URL} C:/TEMP/VisualStudio.chman

ADD https://aka.ms/vs/17/release/vs_buildtools.exe C:/TEMP/vs_buildtools.exe
RUN C:/TEMP/vs_buildtools.exe --quiet --wait --norestart --nocache --installPath C:/buildtools \
				# --all
				--add Microsoft.Component.MSBuild \
				--add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 \
				--add Microsoft.VisualStudio.Component.Windows10SDK.20348 

SHELL ["C:\\buildtools\\Common7\\Tools\\VsDevCmd.bat", "&&", "powershell.exe", "-NoLogo", "-ExecutionPolicy", "Bypass"]

RUN Invoke-WebRequest -UserAgent 'DockerCI' -outfile 7zsetup.exe https://www.7-zip.org/a/7z$env:7ZIP_VERSION-x64.exe
RUN Invoke-WebRequest -UserAgent 'DockerCI' github.com/ghaith/llvm-package-windows/releases/download/v$env:LLVM_VER/LLVM-$env:LLVM_VER-win64.7z -outfile C:/TEMP/llvm.7z
RUN Invoke-WebRequest -UserAgent 'DockerCI' https://win.rustup.rs -outfile C:/TEMP/rustup-init.exe
RUN Invoke-WebRequest -UserAgent 'DockerCI' https://github.com/git-for-windows/git/releases/download/v$env:GIT_VERSION.windows.1/PortableGit-$env:GIT_VERSION-64-bit.7z.exe -outfile C:/TEMP/git-install.exe

#Install 7zip
RUN ./7zsetup /S /D=C:/buildtools/7z
RUN setx /M PATH $($Env:PATH + ';C:/buildtools/7z/') 

# Setup llvm sources
ADD https://github.com/ghaith/llvm-package-windows/releases/download/v$LLVM_VER/LLVM-$LLVM_VER-win64.7z C:/TEMP/llvm.7z


RUN 7z x C:/TEMP/llvm.7z -ollvm 

# Install Rust
# RUN scoop install rustup
ADD https://win.rustup.rs C:/TEMP/rustup-init.exe
RUN C:/TEMP/rustup-init.exe --default-toolchain $env:RUST_VER -y
RUN rustup install nightly

RUN rustup component add llvm-tools-preview 
RUN cargo install mdbook grcov

RUN setx /M PATH $($Env:PATH + ';C:/buildtools/llvm/bin') 


RUN 7z.exe x C:/TEMP/git-install.exe -ogit

#RUN cargo install cargo-watch #Activate this for local builds to enable watching
WORKDIR C:/build

#ENTRYPOINT ["cargo"]
ENTRYPOINT ["C:\\buildtools\\Common7\\Tools\\VsDevCmd.bat", "&&", "C:\\buildtools\\git\\bin\\bash.exe", "-i", "-l"]

