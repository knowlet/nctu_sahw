#!/bin/sh

# env
user='0656091'
pass='****'
agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10.13; rv:57.0) Gecko/20100101 Firefox/57.0"
loginType='captcha-solver'

captcha_solver() {
    # captcha services
    # https://portal.nctu.edu.tw/captcha/pic.php?t=1507195691271
    # https://portal.nctu.edu.tw/captcha/pitctest/pic.php
    # https://portal.nctu.edu.tw/captcha/claviska-simple-php-captcha/simple-php-captcha.php?_CAPTCHA&amp;t=0.68525500+1507195823
    # https://portal.nctu.edu.tw/captcha/securimage/pic.php
    # https://portal.nctu.edu.tw/captcha/cool-php-captcha/pic.php
    code=`curl -sk -b./nctu_cookie.txt -c./nctu_cookie.txt 'https://portal.nctu.edu.tw/captcha/cool-php-captcha/pic.php' | \
    curl -sk --fail 'https://nasa.cs.nctu.edu.tw/sap/2017/hw2/captcha-solver/api/' -X POST -F "image=@-; filename=pic.jpg"`
    if test "$?" != "0"; then
        echo "The curl command failed with: $res";
        captcha_solver
    else
        if test `echo $code | grep ERROR | wc -l` -eq 1; then
            echo $code.
            captcha_solver
        else
            # echo $code.
            captcha="$code"
        fi
    fi
}

captcha_manual() {
    # sudo pkg install imagemagick jp2a
    curl -sk -b./nctu_cookie.txt -c./nctu_cookie.txt -L 'https://portal.nctu.edu.tw/captcha/pic.php' | convert - jpeg:- | jp2a --width=160 -
    read -p "Please input the captcha above (-1 to retry): " captcha
    if [ $captcha == "-1" ]; then captcha_manual; fi
}

login() {
    # create php session and captcha session
    # curl -k -b./nctu_cookie.txt -c./nctu_cookie.txt 'https://portal.nctu.edu.tw/portal/login.php' > /dev/null
    # curl -k -b./nctu_cookie.txt -c./nctu_cookie.txt 'https://portal.nctu.edu.tw/captcha/pitctest/pic.php' > /dev/null
    curl -sk -b./nctu_cookie.txt -c./nctu_cookie.txt -L 'https://portal.nctu.edu.tw/captcha/pic.php' > /dev/null
    captcha="";
    case "$loginType" in
        "1") echo "captcha-solver";
            captcha_solver
        ;;
        "2") echo "manual entering captcha..";
            captcha_manual
        ;;
        "3") echo "captcha-breaker";
            # TODO
        ;;
    esac
    echo "The capthca is: $captcha";
    loginParams="username=$user&Submit2=%E7%99%BB%E5%85%A5%28Login%29&pwdtype=static&password=$pass&seccode=$captcha"
    ret=`curl -L -sk -b./nctu_cookie.txt -c./nctu_cookie.txt 'https://portal.nctu.edu.tw/portal/chkpas.php' -d "$loginParams" | grep alert | wc -l`
    if [ $ret == "0" ]; then
        echo "登入成功";
    else
        echo "登入失敗";
        login
    fi
}

crawl_course() {
    relay=`curl -sk -b./nctu_cookie.txt -c./nctu_cookie.txt -L 'https://portal.nctu.edu.tw/portal/relay.php?D=cos' | grep -o 'value=".*"'`
    # relayParams=`echo "$relay" | node sa2017-hw2/extractFormdata/extractFormdata.js`
    txtPw=`echo "$relay" | awk 'NR==2{print $1}' | cut -f2 -d'"'`
    ldapDN=`echo "$relay" | awk 'NR==3{print $1}' | cut -f2 -d'"'`
    idno=`echo "$relay" | awk 'NR==4{print $1}' | cut -f2 -d'"'`
    s=`echo "$relay" | awk 'NR==5{print $1}' | cut -f2 -d'"'`
    t=`echo "$relay" | awk 'NR==6{print $1}' | cut -f2 -d'"'`
    txtTimestamp=`echo "$relay" | awk 'NR==7{print $1"+"$2}' | cut -f2 -d'"'`
    hashKey=`echo "$relay" | awk 'NR==8{print $1}' | cut -f2 -d'"'`
    jwt=`echo "$relay" | awk 'NR==9{print $1}' | cut -f2 -d'"'`
    relayParams="txtId=&txtPw=$txtPw&ldapDN=$ldapDN&idno=$idno&s=$s&t=$t&txtTimestamp=$txtTimestamp&hashKey=$hashKey&jwt=$jwt&Chk_SSO=on&Button1=%E7%99%BB%E5%85%A5"
    curl -sk -b./nctu_cookie.txt -c./nctu_cookie.txt -L 'https://course.nctu.edu.tw/jwt.asp' -d "$relayParams" > /dev/null
    course=`curl -sk -b./nctu_cookie.txt -c./nctu_cookie.txt 'https://course.nctu.edu.tw/adSchedule.asp' | iconv -f big5 -t utf8`
}

output_course() {
    echo "$course" | grep -v '^\s*$' | grep -E 'nbsp|[^>]<br' | tr -d '\t' | awk -F'[<>]' '{print (NF==3) ? $1 : $5}' | sed 's/&nbsp/./g' | \
    awk 'BEGIN { print "Mon. Tue. Wed. Thu. Fri. Sat. Sun." }
        { printf $0; printf (NR%7) ? "\t" : "\n" }' | \
    column -t
}

init() {
    user=`dialog --title "學號" --inputbox "Enter your school id:" 8 40 0656091 --stdout`
    pass=`dialog --title "密碼" --insecure --passwordbox "Enter your password:" 8 40 --stdout`
    loginType=`dialog --menu "Choose a way to against captcha:" 10 40 2 1 captcha-solver 2 manual --stdout`
}

init
login
crawl_course
output_course
