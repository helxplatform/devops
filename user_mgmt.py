import argparse, re, sys, subprocess, getpass, os.path, shutil

deluser = None
passwd = 'NO'
shell = 'YES'
folder = 'YES'

def check_user(user_name, uid): # done
    with open('/etc/passwd', 'rt') as fd:
        for lines in fd:
            line = lines.split(':')
            if line[0] == user_name:
                continue
            if line[2] == uid:
                continue


def check_group(gid, group): # done
    with open('/etc/group', 'rt') as fd:
        for lines in fd:
            line = lines.split(':')
            if line[0] == group:
                sys.stdout.write("GROUP ALREADY EXISTS")
            if gid in line[2].split(','):
                continue


def set_password(user_name): # done
    if passwd == 'YES':
        psswd = getpass.getpass('Set Password:')
        update_etc_shadow(psswd)
    else:
        update_etc_shadow(user_name, "renci2019$")
        # user created with default password -> "renci2019$"


def password_encoder(psswd): # done
    x = subprocess.check_output(['mkpasswd', '-m', 'sha-512', psswd])
    return x.decode('utf-8')


def update_etc_passwd(home_dir, user_name, uid, gid, shell_value): # done
    with open('/etc/passwd', 'at') as fd:
        line_added = user_name + ":x:" + uid + ":" + gid + ":" + "" + ":" + home_dir + ":" + \
                     shell_value + "\n"
        fd.write(line_added)


def update_etc_shadow(user_name, psswd): # done
    with open('/etc/shadow', 'at') as fd:
        line_added = user_name + ":" + password_encoder(psswd).strip() + ":18006:90:90:30:::" + "\n"
        #Account Expiry 90 days, warning for change password 30 days.
        fd.write(line_added)


def mk_home_dir(user_name): # done
    home_dir = '/home/' + user_name
    subprocess.call(['mkdir', home_dir])
    if os.path.exists('/etc/skel/'):
        copytree('/etc/skel', home_dir)
    return home_dir


def copytree(src, dst, symlinks=False, ignore=None): # done
    for item in os.listdir(src):
        s = os.path.join(src, item)
        d = os.path.join(dst, item)
        if os.path.isdir(s):
            shutil.copytree(s, d, symlinks, ignore)
        else:
            shutil.copy2(s, d)


def update_etc_group(user_name, gid, group): # done
    with open('/etc/group', 'at') as fd:
        if group:
            group_name = group
        else:
            group_name = user_name
        if gid:
            group_id = gid
        else:
            raise SystemExit("default GID is required")
        line_added = group_name + ":x:" + group_id + ":" + user_name + "\n"
        fd.write(line_added)


def main():
    with open("/data/templates/config1.txt",'r') as fd:
        for line in fd:
            raw_line = line.strip("\n").split("\t")
            user_name = raw_line[0]
            uid = raw_line[1]
            gid = raw_line[2]
            if deluser is None:
                check_user(user_name, uid)
                check_group(gid, group=None)
                set_password(user_name)
                if shell == 'NO':
                    if folder == 'NO':
                        home_dir = '/'
                        update_etc_passwd(home_dir, shell_value='/usr/sbin/nologin')
                    else:
                        home_dir = mk_home_dir(user_name)
                        update_etc_passwd(home_dir, shell_value='/usr/sbin/nologin')
                        subprocess.call(["sudo", "chown", user_name, home_dir])
                        subprocess.call(["sudo", "chmod", "770", home_dir])
                else:
                    if folder == 'NO':
                        home_dir = '/'
                        update_etc_passwd(home_dir, shell_value='/bin/bash')
                    else:
                        home_dir = mk_home_dir(user_name)
                        print(home_dir)
                        update_etc_passwd(home_dir, user_name, uid, gid, shell_value='/bin/bash')
                        subprocess.call(["sudo", "chown", user_name, home_dir])
                        subprocess.call(["sudo", "chmod", "770", home_dir])
                        subprocess.call(["sudo", "usermod", "-a", "-G", "rstudio_whitelist", user_name])
                update_etc_group(user_name, gid, group=None)
            else:
                print("gggggg")


if __name__ == '__main__':
    main()
