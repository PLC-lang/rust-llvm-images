# escape=`

# Use the latest Windows Server Core image with .NET Framework 4.8.
FROM mcr.microsoft.com/dotnet/framework/sdk:4.8-windowsservercore-ltsc2019

ARG LLVM_VER=13.0.0
ARG RUST_VER=1.60.0

# Install depedencies
ARG 7ZIP_VERSION=2107

RUN mkdir C:\buildtools
RUN mkdir C:\TEMP

WORKDIR C:\buildtools

# Start on poweshell
SHELL ["powershell.exe", "-NoLogo", "-ExecutionPolicy", "Bypass"]
# Run some dowloads early 
RUN Invoke-WebRequest -UserAgent 'DockerCI' -outfile 7zsetup.exe https://www.7-zip.org/a/7z$env:7ZIP_VERSION-x64.exe
RUN Invoke-WebRequest -UserAgent 'DockerCI' github.com/ghaith/llvm-package-windows/releases/download/v$env:LLVM_VER/LLVM-$env:LLVM_VER-win64.7z -outfile C:/TEMP/llvm.7z
RUN Invoke-WebRequest -UserAgent 'DockerCI' https://win.rustup.rs -outfile C:/TEMP/rustup-init.exe

# Install 7Zip
RUN start-process .\7zsetup -ArgumentList '/S /D=c:/7zip' -Wait
RUN setx /M PATH $($Env:PATH + ';C:/7zip') 

# Extract llvm sources
RUN 7z x C:/TEMP/llvm.7z -ollvm 

# Install Rust
RUN C:/TEMP/rustup-init.exe --default-toolchain $env:RUST_VER -y
# RUN setx /M PATH $($Env:PATH ';%USERPROFILE%\.cargo\bin')
RUN rustup component add llvm-tools-preview

RUN setx /M PATH $($Env:PATH + ';C:/buildtools/llvm/bin') 

RUN Invoke-WebRequest -useb https://github.com/git-for-windows/git/releases/download/v2.33.1.windows.1/PortableGit-2.33.1-64-bit.7z.exe -outfile C:/TEMP/git-install.exe

RUN 7z x C:/TEMP/git-install.exe -ogit

# Restore the default Windows shell for correct batch processing.
SHELL ["cmd", "/S", "/C"]

RUN `
    # Download the Build Tools bootstrapper.
    curl -SL --output C:\Temp\vs_buildtools.exe https://aka.ms/vs/17/release/vs_buildtools.exe `
    `
    # Install Build Tools with the Microsoft.VisualStudio.Workload.AzureBuildTools workload, excluding workloads and components with known issues.
    && (start /w C:\Temp\vs_buildtools.exe --quiet --wait --norestart --nocache `
        --installPath C:\buildtools `
		--add Microsoft.Component.MSBuild `
		--add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
		--add Microsoft.VisualStudio.Component.Windows10SDK.22000 `
		--add Microsoft.VisualStudio.Component.Windows10SDK.17763 `
        || IF "%ERRORLEVEL%"=="3010" EXIT 0) `
    `
    # Cleanup
    && del /q C:\Temp\vs_buildtools.exe
RUN setx /M __VSCMD_ARG_NO_LOGO "1"
# VS install done, install extra compoments
# Switch to powershell for the remainder of the build
SHELL ["powershell.exe", "-NoLogo", "-ExecutionPolicy", "Bypass"]

RUN cargo install mdbook grcov

RUN mkdir C:\build
WORKDIR C:\build

ENTRYPOINT ["C:\\buildtools\\git\\bin\\bash.exe", "-i", "-l"]
