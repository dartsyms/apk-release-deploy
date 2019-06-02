FROM ubuntu:18.04
MAINTAINER United Developers <info@udev.dev>

ENV VERSION_SDK_TOOLS "28.0.0"
ENV VERSION_BUILD_TOOLS "28.0.0"
ENV VERSION_TARGET_SDK "28"
ENV VERSION_SDK_TOOLS_REV "4333796"

ENV VERSION_ANDROID_NDK "android-ndk-r19c"
ENV ANDROID_NDK_HOME "/sdk/${VERSION_ANDROID_NDK}"
ENV ANDROID_CMAKE_REV "3.6.4111459"
ENV ANDROID_CMAKE_REV_3_10 "3.10.2.4988404"
ENV ANDROID_EMULATOR_PACKAGE "system-images;android-28;google_apis;x86"

ENV ANDROID_HOME "/sdk"
ENV PATH "$PATH:${ANDROID_HOME}/tools"
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -qq update && \
    apt-get install -qqy --no-install-recommends \
      build-essential \ 
      file \ 
      curl \
      html2text \
      openjdk-8-jdk \
      libc6-i386 \
      lib32stdc++6 \
      lib32gcc1 \
      lib32ncurses5 \
      lib32z1 \
      unzip \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN rm -f /etc/ssl/certs/java/cacerts; \
    /var/lib/dpkg/info/ca-certificates-java.postinst configure

RUN curl -s https://dl.google.com/android/repository/sdk-tools-linux-${VERSION_SDK_TOOLS_REV}.zip > /tools.zip && \
    unzip /tools.zip -d /sdk && \
    rm -v /tools.zip

RUN mkdir -p $ANDROID_HOME/licenses/ \
  && echo "8933bad161af4178b1185d1a37fbf41ea5269c55\nd56f5187479451eabf01fb78af6dfcb131a6481e\n24333f8a63b6825ea9c5514f83c2829b004d1fee" > $ANDROID_HOME/licenses/android-sdk-license \
  && echo "84831b9409646a918e30573bab4c9c91346d8abd\n504667f4c0de7af1a06de9f4b1727b84351f2910" > $ANDROID_HOME/licenses/android-sdk-preview-license 

ADD packages.txt /sdk
RUN mkdir -p /root/.android && \
  touch /root/.android/repositories.cfg && \
  ${ANDROID_HOME}/tools/bin/sdkmanager --update 

RUN while read -r package; do PACKAGES="${PACKAGES}${package} "; done < /sdk/packages.txt && \
    ${ANDROID_HOME}/tools/bin/sdkmanager ${PACKAGES}

RUN yes | ${ANDROID_HOME}/tools/bin/sdkmanager --licenses

ADD https://dl.google.com/android/repository/$VERSION_ANDROID_NDK-linux-x86_64.zip /ndk.zip
RUN unzip /ndk.zip -d /sdk && \
    rm -v /ndk.zip

RUN echo no | \ 
    ${ANDROID_HOME}/tools/bin/avdmanager create avd -n "x86" --package "${ANDROID_EMULATOR_PACKAGE}" --tag google_apis

#RUN curl -s https://github.com/Commit451/android-cmake-installer/releases/download/1.1.0/install-cmake.sh > install-cmake.sh; \
#    chmod +x install-cmake.sh; \
#    ./install-cmake.sh; \
#    rm -v install-cmake.sh

