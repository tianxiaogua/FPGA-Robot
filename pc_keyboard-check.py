#!/usr/bin/python3.7
#encoding:utf-8
import pynput
import threading
from socket import *
import threading
address="192.168.31.106"   #8266的服务器的ip地址
port=8266           #8266的服务器的端口号
buffsize=1024        #接收数据的缓存大小
s=socket(AF_INET, SOCK_STREAM)
s.connect((address,port))

def fun():
    while True:
        recvdata=s.recv(buffsize).decode('utf-8')
        print("\n接收的数据是："+recvdata)
        #for i in recvdata:
         #   if(i is not 0):
          #      print('%#x' % ord(i))

t = threading.Thread(target=fun)  # t为新创建的线程，专门用来接收从服务器发送过来的数据
t.start()

#while True:
#    senddata=input('\n想要发送的数据：')
#    if senddata=='exit':
#        break
#   s.send(senddata.encode())
#    #recvdata=s.recv(buffsize).decode('utf-8')
#    #print(recvdata)，。。。，，。。，，。。aqsqdqaq,,,,............jjjjlllllljjjjjjjjjjjjjllllllllllllllllllkkkkkkkkuuuuuuuuuukkkjjjjjjhhiiihihihihhiihihiihihihih...,,,,,,,,,,,,,ljljljljljljljljlqdqaqdqwqdqwqsqdqdqaqaqaqdq.,.,,..........iiiiuuuujjjljljjjjllllllllllllhhhhhhhhhhhh,,,,,mmmmm,,,........yyuuuuuuuuuuuuukkkkkkkkkllkjjjjjjjjjzxx
#s.close()


"""此模块用来做上位机，把电脑当作遥控器来对机器人进行控制
"""
keyboard = pynput.keyboard.Controller()

#TCP = Tcp_server()
#Clientsock, Clientaddress = TCP.wait_connect()
#thread = threading.Thread(target=TCP.reve_massage,
#                          args=(Clientsock, Clientaddress))  # t为新创建的线程
#thread.start()

"""把获取的键盘值显示出来"""
def on_press(key):
    try:
        print("key {} pressed".format(key.char))#输入类似abcd的值可以直接传换成字符串打印出来
        if key.char is 's':
            print("向后")
            senddata = '2'
            s.send(senddata.encode())
            #contro_main.Driver_Set_Engine('a4a4')
            #TCP.send_massage("a4a4", Clientsock, Clientaddress)
        elif key.char is 'w':
            print("向前")
            senddata = '1'
            s.send(senddata.encode())
            #contro_main.Driver_Set_Engine('g8g8')
            #TCP.send_massage("g8g8", Clientsock, Clientaddress)
        elif key.char is 'd':
            print("向左")
            senddata = '4'
            s.send(senddata.encode())
            #contro_main.Driver_Set_Engine('g7a4')
            #TCP.send_massage("g7a4", Clientsock, Clientaddress)
        elif key.char is 'a':
            print("向右")
            senddata = '3'
            s.send(senddata.encode())
            #contro_main.Driver_Set_Engine('a4g7')
            #TCP.send_massage("a4g7", Clientsock, Clientaddress)
        elif key.char is 'q':
            print("撒车")
            senddata = '5'
            s.send(senddata.encode())


        elif key.char is 'i':
            print("左转头")
            senddata = '7'
            s.send(senddata.encode())
        elif key.char is 'k':
            print("右转头")
            senddata = '6'
            s.send(senddata.encode())


        elif key.char is 'h':
            print("左转头")
            senddata = '9'
            s.send(senddata.encode())
        elif key.char is 'u':
            print("右转头")
            senddata = '8'
            s.send(senddata.encode())


        elif key.char is 'j':
            print("左转头")
            senddata = 'a'
            s.send(senddata.encode())
        elif key.char is 'l':
            print("右转头")
            senddata = 'b'
            s.send(senddata.encode())


        elif key.char is ',':
            print("左转头")
            senddata = 'c'
            s.send(senddata.encode())
        elif key.char is '.':
            print("右转头")
            senddata = 'd'
            s.send(senddata.encode())

        elif key.char is 'z':
            print("测距")
            senddata = 'e'
            s.send(senddata.encode())

        elif key.char is 'x':
            print("测距")
            senddata = 'f'
            s.send(senddata.encode())

    except AttributeError:
        print("special key {} pressed".format(key))#打印出来类似空格shift这样的功能按键

"""键盘抬起检测"""
def on_release(key):
    try:
        print("{} released".format(key))
        #TCP.send_massage("a0a0", Clientsock, Clientaddress)
    except AttributeError:
        print("special key {} pressed".format(key))#打印出来类似空格shift这样的功能按键



# 键盘添加监听器
with pynput.keyboard.Listener(on_press=on_press, on_release=on_release) as listener:
    listener.join()



