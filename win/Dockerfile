FROM mcr.microsoft.com/windows/servercore:ltsc2019

ARG LLVM_VER=13.0.0
ARG RUST_VER=1.59.0

WORKDIR C:/buildtools

SHELL ["powershell.exe", "-NoLogo", "-ExecutionPolicy", "Bypass"]

# Install depedencies
ARG 7ZIP_VERSION=2107

RUN Invoke-WebRequest -UserAgent 'DockerCI' -outfile 7zsetup.exe https://www.7-zip.org/a/7z$env:7ZIP_VERSION-x64.exe

RUN start-process .\7zsetup -ArgumentList '/S /D=c:/7zip' -Wait

RUN setx /M PATH $($Env:PATH + ';C:/7zip') 

RUN mkdir "C:/TEMP"

# Setup llvm sources
RUN Invoke-WebRequest -useb github.com/ghaith/llvm-package-windows/releases/download/v$env:LLVM_VER/LLVM-$env:LLVM_VER-win64.7z -outfile C:/TEMP/llvm.7z

RUN 7z x C:/TEMP/llvm.7z -ollvm 

# Install Rust
# RUN scoop install rustup
RUN Invoke-WebRequest -useb https://win.rustup.rs -outfile C:/TEMP/rustup-init.exe
RUN C:/TEMP/rustup-init.exe --default-toolchain $env:RUST_VER -y
RUN rustup install nightly

RUN setx /M PATH $($Env:PATH + ';C:/buildtools/llvm/bin') 

RUN Invoke-WebRequest -useb https://github.com/git-for-windows/git/releases/download/v2.33.1.windows.1/PortableGit-2.33.1-64-bit.7z.exe -outfile C:/TEMP/git-install.exe

RUN 7z x C:/TEMP/git-install.exe -ogit

# Install VC++
# Download channel for fixed install.
ARG CHANNEL_URL=https://aka.ms/vs/16/release/channel
ADD ${CHANNEL_URL} C:/TEMP/VisualStudio.chman

ADD https://aka.ms/vs/16/release/vs_buildtools.exe C:/TEMP/vs_buildtools.exe
RUN C:/TEMP/vs_buildtools.exe --quiet --wait --norestart --nocache --installPath C:/buildtools \
				--add Microsoft.Component.MSBuild \
				--add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 \
				--add Microsoft.VisualStudio.Component.Windows10SDK.20348 




SHELL ["C:\\buildtools\\Common7\\Tools\\VsDevCmd.bat", "&&", "C:\\buildtools\\git\\bin\\bash.exe", "-i", "-l"]
# VS install done, install extra compoments
RUN rustup component add llvm-tools-preview
RUN cargo install mdbook grcov
#RUN cargo install cargo-watch #Activate this for local builds to enable watching

WORKDIR C:/build
ENTRYPOINT ["C:\\buildtools\\Common7\\Tools\\VsDevCmd.bat", "&&", "C:\\buildtools\\git\\bin\\bash.exe", "-i", "-l"]

