# Use Ubuntu 22.04 as base image
FROM ubuntu:22.04

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Update system and install essential packages
RUN apt-get update && apt-get install -y \
    curl \
    git \
    wget \
    unzip \
    zip \
    xz-utils \
    build-essential \
    libstdc++6 \
    lib32z1 \
    lib32stdc++6 \
    libc6-dev \
    libgcc1 \
    libncurses5 \
    libstdc++6 \
    libtinfo5 \
    zlib1g \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Set up user
ARG USERNAME=developer
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Install Java 17 (required for Android development)
RUN apt-get update && apt-get install -y openjdk-17-jdk && rm -rf /var/lib/apt/lists/*
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH

# Install Android SDK
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_HOME=$ANDROID_SDK_ROOT
ENV PATH=$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH

RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools \
    && wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip \
    && unzip commandlinetools-linux-11076708_latest.zip -d $ANDROID_SDK_ROOT/cmdline-tools \
    && mv $ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools $ANDROID_SDK_ROOT/cmdline-tools/latest \
    && rm commandlinetools-linux-11076708_latest.zip

# Accept Android SDK licenses and install required packages
RUN yes | sdkmanager --licenses
RUN sdkmanager \
    "platform-tools" \
    "platforms;android-34" \
    "platforms;android-33" \
    "build-tools;34.0.0" \
    "build-tools;33.0.2" \
    "ndk;25.1.8937393" \
    "cmake;3.22.1"

# Install Flutter SDK
ENV FLUTTER_VERSION=3.24.3
ENV FLUTTER_HOME=/opt/flutter
ENV PATH=$FLUTTER_HOME/bin:$PATH

RUN wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz \
    && tar xf flutter_linux_${FLUTTER_VERSION}-stable.tar.xz -C /opt \
    && rm flutter_linux_${FLUTTER_VERSION}-stable.tar.xz

# Install Kotlin (latest version)
ENV KOTLIN_VERSION=1.9.20
RUN wget -q https://github.com/JetBrains/kotlin/releases/download/v${KOTLIN_VERSION}/kotlin-compiler-${KOTLIN_VERSION}.zip \
    && unzip kotlin-compiler-${KOTLIN_VERSION}.zip -d /opt \
    && rm kotlin-compiler-${KOTLIN_VERSION}.zip
ENV PATH=/opt/kotlinc/bin:$PATH

# Install Gradle
ENV GRADLE_VERSION=8.4
RUN wget -q https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip \
    && unzip gradle-${GRADLE_VERSION}-bin.zip -d /opt \
    && rm gradle-${GRADLE_VERSION}-bin.zip
ENV PATH=/opt/gradle-${GRADLE_VERSION}/bin:$PATH

# Set proper ownership for Android SDK and Flutter
RUN chown -R $USERNAME:$USERNAME $ANDROID_SDK_ROOT $FLUTTER_HOME

# Switch to non-root user
USER $USERNAME
WORKDIR /home/$USERNAME

# Configure Flutter
RUN flutter config --android-sdk $ANDROID_SDK_ROOT
RUN flutter config --no-analytics
RUN flutter doctor --android-licenses

# Pre-download Flutter dependencies
RUN flutter precache

# Create app directory
WORKDIR /app

# Copy project files
COPY --chown=$USERNAME:$USERNAME . .

# Install Flutter dependencies
RUN flutter pub get

# Configure Git (required for some Flutter operations)
RUN git config --global --add safe.directory /app

# Build the application for different platforms
# You can uncomment the builds you need:

# Build for web
RUN flutter build web --release

# Build for Android APK (uncomment if needed)
# RUN flutter build apk --release

# Build for Android App Bundle (uncomment if needed)
# RUN flutter build appbundle --release

# Build for Linux (uncomment if needed)
# RUN flutter build linux --release

# Expose port for web server (if running web build)
EXPOSE 8080

# Set environment variables for runtime
ENV FLUTTER_WEB_PORT=8080
ENV FLUTTER_WEB_HOSTNAME=0.0.0.0

# Create a simple HTTP server script for serving the web build
RUN echo '#!/bin/bash\n\
cd /app/build/web\n\
python3 -m http.server $FLUTTER_WEB_PORT --bind $FLUTTER_WEB_HOSTNAME\n\
' > /app/serve_web.sh && chmod +x /app/serve_web.sh

# Install Python for serving web content
USER root
RUN apt-get update && apt-get install -y python3 && rm -rf /var/lib/apt/lists/*
USER $USERNAME

# Default command to serve the web build
CMD ["/app/serve_web.sh"]

# Alternative commands you can use:
# For development with hot reload: CMD ["flutter", "run", "--web-port", "8080", "--web-hostname", "0.0.0.0"]
# For Android development: CMD ["flutter", "run", "--release"]
# For running tests: CMD ["flutter", "test"]