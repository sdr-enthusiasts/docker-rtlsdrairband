# docker-rtlsdrairband

Quick readme file until I get this fully working.

Docker container to run [RTLSDR-Airband](https://github.com/szpajder/RTLSDR-Airband)
 
No ENV variables

Needs one volume mounted in the container at `/usr/local/etc/` which has the `rtl_airband.conf` file.

Example rtl_airband.conf

```
fft_size = 512;
devices: (
  {
    type = "rtlsdr";
    index = 0;
    gain = 25;
    centerfreq = 120000000;
    correction = 80;
    mode = "scan";
    channels:
    (
      {
        freqs = ( 123.9, 124.325, 125.45, 127.4, 124.4, 134.8, 133.65, 132.8, 126.3 );
        outputs: (
          {
            type = "icecast";
            server = "192.168.31.223";
            port = 8000;
            mountpoint = "TWR.mp3";
            name = "Tower";
            genre = "ATC";
            username = "source";
            password = "Propilot11!!";
          }
        )
      }
    );
  }
);
```
