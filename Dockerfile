# ====================================================================== #
# Android SDK Docker Image
# ====================================================================== #

# Base image
# ---------------------------------------------------------------------- #
FROM ubuntu:20.04

# Author
# ---------------------------------------------------------------------- #
LABEL maintainer "o.mineev@movavi.com"

# support multiarch: i386 architecture
# install Java
# install essential tools
ARG JDK_VERSION=8
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends libncurses5:i386 libc6:i386 libstdc++6:i386 lib32gcc1 lib32ncurses6 lib32z1 zlib1g:i386 && \
    apt-get install -y --no-install-recommends openjdk-${JDK_VERSION}-jdk && \
    apt-get install -y --no-install-recommends git wget unzip socat

# download and install Android SDK
# https://developer.android.com/studio#command-tools
ARG ANDROID_SDK_VERSION=6609375
ENV ANDROID_SDK_ROOT /opt/android-sdk
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_VERSION}_latest.zip && \
    unzip *tools*linux*.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools && \
    rm *tools*linux*.zip

# set the environment variables
ENV JAVA_HOME /usr/lib/jvm/java-${JDK_VERSION}-openjdk-amd64
ENV PATH ${PATH}:${ANDROID_SDK_ROOT}/cmdline-tools/tools/bin:${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/emulator
ENV _JAVA_OPTIONS -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap

RUN sdkmanager "emulator" "tools" "platform-tools"
RUN yes | sdkmanager --update --channel=3
RUN yes | sdkmanager \
    "platforms;android-29" \
    "build-tools;28.0.3" \
    "system-images;android-29;google_apis;x86"

# accept the license agreements of the SDK components
ADD license_accepter.sh /opt/
RUN chmod +x /opt/license_accepter.sh && /opt/license_accepter.sh $ANDROID_SDK_ROOT

# Fix emulator from crashing when running as root user.
# See https://github.com/budtmo/docker-android/issues/223
ENV QTWEBENGINE_DISABLE_SANDBOX=1

RUN mkdir -p /root/.android
ADD adbkey /root/.android/
ADD adbkey.pub /root/.android/

RUN avdmanager create avd -n 'Emulator' -k "system-images;android-29;google_apis;x86" --device "pixel_3a"

COPY ./docker-entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/docker-entrypoint.sh


EXPOSE 5555

HEALTHCHECK CMD \[ $(adb shell getprop sys.boot_completed) \] || exit 1
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["emulator", "@Emulator", "-no-boot-anim", "-no-window", "-no-audio", "-wipe-data", "-partition-size", "4192"]
