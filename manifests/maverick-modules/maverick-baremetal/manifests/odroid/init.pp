class maverick-baremetal::odroid::init (
    $governor_atboot = "ondemand"
) {

    ensure_packages(["axel", "whiptail"])

    # Add odroid-utility repo from git, contains useful scripts
    file { "/srv/maverick/software/odroid-utility":
        ensure 		=> directory,
        require		=> File["/srv/maverick/software"],
        mode		=> 755,
        owner		=> "mav",
        group		=> "mav",
    } ->
    oncevcsrepo { "git-odroid-utility":
        gitsource   => "https://github.com/mdrjr/odroid-utility.git",
        dest        => "/srv/maverick/software/odroid-utility",
    }
    
    # Add odroid-cpu-control from git, very useful
    file { "/srv/maverick/software/odroid-cpu-control":
        ensure 		=> directory,
        require		=> File["/srv/maverick/software"],
        mode		=> 755,
        owner		=> "mav",
        group		=> "mav",
    } ->
    oncevcsrepo { "git-odroid-cpu-control":
        gitsource   => "https://github.com/mad-ady/odroid-cpu-control.git",
        dest        => "/srv/maverick/software/odroid-cpu-control",
    } ->
    file { "/srv/maverick/software/maverick/bin/cpu-control":
        ensure      => link,
        target      => "/srv/maverick/software/odroid-cpu-control/odroid-cpu-control",
    }
    
    # Change default governor at boot
    #  .. first reset all governors except what we want
    exec { "odroid-boot-governor-others":
        command     => '/bin/sed /media/boot/boot.ini -i -r -e "/^setenv governor \"${governor_atboot}\"/! s/^(setenv governor)\s(=[^,]*)?/\# setenv governor $1/"',
        onlyif      => "/bin/grep '^setenv governor' /media/boot/boot.ini | /bin/grep -v ${governor_atboot}"
    } ->
    # .. then set the requested governor
    exec { "odroid-boot-governor-requested":
        command     => "/bin/sed /media/boot/boot.ini -i -r -e 's/^# setenv governor \"${governor_atboot}\"/setenv governor \"${governor_atboot}\"/'",
        onlyif      => "/bin/grep '^# setenv governor \"${governor_atboot}\"' /media/boot/boot.ini"
    }
    concat { "/etc/profile.d/maverick-path-odroid.sh":
        ensure      => present,
    }
    concat::fragment { "maverickpath-cpucontrol":
        target      => "/etc/profile.d/maverick-path-odroid.sh",
        order       => 10,
        content     => "PATH=\$PATH:/srv/maverick/software/odroid-cpu-control",
    }

    # Supress irritating kernel messages
    exec { "xu4-blacklist-mod":
        command     => "/bin/echo 'blacklist ina231_sensor' >>/etc/modprobe.d/blacklist-odroid.conf",
        unless      => "/bin/grep ina231_sensor /etc/modprobe.d/blacklist-odroid.conf",
    }
    
    # Ensure Mali GL libraries are installed
    package { "mali-x11":
        ensure      => absent
    } ->
    package { "mali-fbdev":
        ensure      => present
    }
    
    # Add odroid-wiringpi from hardkernel github
    file { "/srv/maverick/software/odroid-wiringpi":
        ensure 		=> directory,
        require		=> File["/srv/maverick/software"],
        mode		=> 755,
        owner		=> "mav",
        group		=> "mav",
    } ->
    oncevcsrepo { "git-odroid-wiringpi":
        gitsource   => "https://github.com/hardkernel/wiringPi.git",
        dest        => "/srv/maverick/software/odroid-wiringpi",
    } ->
    exec { "compile-wiringpi":
        command     => "/srv/maverick/software/odroid-wiringpi/build >/srv/maverick/data/logs/build/odroid-wiringpi.build.log 2>&1",
        cwd         => "/srv/maverick/software/odroid-wiringpi",
        creates     => "/srv/maverick/software/odroid-wiringpi/wiringPi/libwiringPi.so.2.0",
    }
    
}