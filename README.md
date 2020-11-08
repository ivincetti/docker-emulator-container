# docker-emulator-container
build container
```docker build -t asdk .```

run container
```docker run -d -p 5555:5555 -p 5554:5554 --device /dev/kvm --privileged --name=aSDK  asdk```

in container auto started
```emulator @Emulator -no-window -wipe-data -noaudio -no-boot-anim -partition-size 4192```

to use emulator use
```adb connect *DOCKER_HOST*:5555```
