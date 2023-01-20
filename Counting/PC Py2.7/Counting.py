#!C:\\Python27\python.exe
# runs under Windows, Python 3.9 + wxPython + PySerial
#
'''
####----------------------------------------------------------------------
####
#### Nuclear Counter in Python
####     Use with Arduino Uno program Counting.ino
####	   or with test program TestCounting.ino
####
	Author: Dan Briotta
	Modified by Jerome Fung to work with Python 3
####----------------------------------------------------------------------
'''

import wx
if (wx.__version__[0]=='4'):
	import wx.adv
import os
#import matplotlib
#matplotlib.use('WXAgg')
#import matplotlib.figure as plt
#from matplotlib.backends.backend_wxagg import FigureCanvasWxAgg as FigureCanvas
#import numpy as np
import serial
import serial.tools.list_ports
import sys

####----------------------------------------------------------------------
####
#### Global Initialization
####
####----------------------------------------------------------------------
ser = serial.Serial()

class MainWindow(wx.Frame):
	def __init__(self, parent, title, position, size):
		global counting
		self.counting=False
		self.datacount=0
		self.datamax=0
		################## Connect to Arduino Uno
		self.unoPort = 'None'
		self.unoMsg = 'No Uno Connected.'
		self.ConnectToUno()
		################## Create main window
		wx.Frame.__init__(self, parent, title=title, pos=position, size=size)
		#self.__close_callback = None
		self.Bind(wx.EVT_CLOSE,self.onQuit)
		################## create things
### MenuBar
		menubar = wx.MenuBar()
		filemenu = wx.Menu()
		self.aboutItem = filemenu.Append(wx.ID_ABOUT,'&About Nuclear Counter')
		filemenu.AppendSeparator()
		self.saveItem = filemenu.Append(-1,"Save Counts...\tCtrl+S")
		self.quitItem = filemenu.Append(-1,'Quit...\tCtrl+Q')
		menubar.Append(filemenu,"&File")
		self.SetMenuBar(menubar)
		self.Bind(wx.EVT_MENU, self.onAboutBox, self.aboutItem)
		self.Bind(wx.EVT_MENU, self.onSave, self.saveItem)
		self.Bind(wx.EVT_MENU, self.onQuit, self.quitItem)
### widgets
		modeList = ['Free Run', 'Stop after N data points']   
		self.rbox=wx.RadioBox(self,-1,"Mode:",wx.DefaultPosition,
			wx.DefaultSize,
			choices = modeList,
			majorDimension = 2, 
			style = wx.RA_SPECIFY_ROWS)
		self.Bind(wx.EVT_RADIOBOX,self.onRadioBox,self.rbox)
#
		self.intervallabel = wx.StaticText(self,label="T =")
		self.intervalinput = wx.TextCtrl(self,value="1000",style=wx.TE_RIGHT)
		self.intervalunit  = wx.StaticText(self,label="millisec.")
		self.inputsizer    = wx.BoxSizer(wx.HORIZONTAL)
		self.inputsizer.Add(self.intervallabel,0,wx.LEFT,5)
		self.inputsizer.Add(self.intervalinput,0,wx.LEFT,5)
		self.inputsizer.Add(self.intervalunit,0,wx.LEFT,5)
#		
		self.countlabel = wx.StaticText(self,label="N =")
		self.countinput = wx.TextCtrl(self,value="10",style=wx.TE_RIGHT)
		self.countsizer = wx.BoxSizer(wx.HORIZONTAL)
		self.countsizer.Add(self.countlabel,0,wx.LEFT,5)
		self.countsizer.Add(self.countinput,0,wx.LEFT,5)
#
		self.gobutton = wx.ToggleButton(self,wx.ID_ANY,"Go",size=(225,-1))
		#self.Bind(wx.EVT_BUTTON,self.onGoButton)
		self.Bind(wx.EVT_TOGGLEBUTTON,self.onGoButton)
#
		self.logger = wx.TextCtrl(self,5,"",(0,0),(225,500),\
			wx.TE_MULTILINE | wx.TE_READONLY | wx.TE_RIGHT)
#	Stack them vertically	
		sizer=wx.BoxSizer(wx.VERTICAL)
		sizer.AddSpacer(10)
		sizer.Add(self.rbox,0,wx.LEFT|wx.RIGHT,20)
		sizer.Add(self.inputsizer,0,wx.LEFT,40)
		sizer.AddSpacer(10)
		sizer.Add(self.countsizer,0,wx.LEFT,40)
		sizer.AddSpacer(10)
		sizer.Add(self.gobutton,0,wx.LEFT,40)
		sizer.AddSpacer(10)
		sizer.Add(self.logger,0,wx.LEFT,40)
		
		self.SetSizer(sizer)
		self.Show()
		#self.ShowWithEffect(wx.SHOW_EFFECT_ROLL_TO_BOTTOM)
		self.Layout()
		self.Bind(wx.EVT_IDLE, self.onIdle) # for data collection!
####----------------------------------------------------------------------
####
#### EVENTS:
####
####----------------------------------------------------------------------
	def onAboutBox(self,event):
		if wx.__version__[0]=='4':
			info = wx.adv.AboutDialogInfo()
		else:
			info = wx.AboutDialogInfo()
		info.SetName('Nuclear Counter')
		info.SetVersion('0.9.8',longVersion='0.9 Alpha')
		info.SetDescription('Nuclear Counting using an Arduino Uno')
		info.AddDeveloper('Dan Briotta\nJan, 2018')
		if wx.__version__[0]=='4':
			wx.adv.AboutBox(info)
		else:
			wx.AboutBox(info)
	#----------------------------------------------------------------------		
	def onIdle(self,event):
		global remains,datacount,counting
		####if (self.datacount < self.datamax):
		####	self.datacount = self.datacount+1
		####	self.logger.AppendText(str(self.datacount)+"\n")
		if self.ser.inWaiting()>0:
			ins = self.ser.read(self.ser.inWaiting()).decode('utf-8')
			data = (self.remains + ins).split()
			#### check remains carried properly:
			#print "("+self.remains+")"+ins.split()[0]+"="+data[0]+","+data[1]
			if (ins[-1] != "\n"):
				self.remains = data.pop()
			else:
				self.remains = ""
			#print len(data)
			for d in data:
				self.logger.AppendText(str(d)+"\n")
				if (self.rbox.GetSelection()):
					self.datacount = self.datacount+1
					if (self.datacount >= self.datamax):
						self.ser.write('s'.encode('utf-8')) # stop Uno data stream
						self.counting=False
						self.gobutton.SetLabel("Go")
						self.gobutton.SetValue(0)
		event.RequestMore(True)
	#----------------------------------------------------------------------		
	def onRadioBox(self,event):
		#print "Radio box selection = ",self.rbox.GetSelection()
		if (self.rbox.GetSelection() == 0):
			print("Mode = Free Run")
			#self.intervalinput.SetValue(str(1000))
		else:
			print("Mode = Collect Data")
		self.ser.write('s'.encode('utf-8')) # stop Uno data stream
		self.counting=False
		self.gobutton.SetLabel("Go")
		self.gobutton.SetValue(0)
	#----------------------------------------------------------------------		
	def onGoButton(self,event):
		global remains,counting
		if (self.counting):
			self.ser.write('s'.encode('utf-8'))
			self.counting=False
			self.gobutton.SetLabel("Go")
			self.gobutton.SetValue(0)
		else:
			print("Go...")
			#print self.logger.GetValue()
			print("Time = ",self.intervalinput.GetValue())
			print("Number = ",self.countinput.GetValue())
			self.logger.SetValue("")
			self.datacount = 0
			#
			self.datacount = 0
			self.datamax = int(self.countinput.GetValue())
			self.remains=""
			#print(self.intervalinput.GetValue())
			self.ser.write(('s'+str(self.intervalinput.GetValue())+'g').encode('utf-8'))
			self.counting=True
			self.gobutton.SetLabel("Stop")
			self.gobutton.SetValue(1)
	#----------------------------------------------------------------------
	def onSave(self,event):
		if (len(self.logger.GetValue()) > 0):
			dlg = wx.FileDialog(self, "Save data as...", \
			os.getcwd(), "", "*.txt", \
				style=wx.FD_SAVE|wx.FD_OVERWRITE_PROMPT)
			result = dlg.ShowModal()
			inFile = dlg.GetPath()
			dlg.Destroy()
			if result == wx.ID_OK:			#Save button was pressed
				print("Saving data to",inFile)
				filehandle = open(inFile,'w')
				filehandle.write(self.logger.GetValue())
				filehandle.close()
			elif result == wx.ID_CANCEL:	#Cancel button was pressed
				#print "Save data cancelled."
				dlg = wx.MessageDialog(self,"","Save Count cancelled!",
					wx.OK | wx.ICON_INFORMATION)
				dlg.ShowModal()
				dlg.Destroy()
		else:
			#print "Nothing to save!"
			dlg = wx.MessageDialog(self,"Nothing to save!","Whoops!",
				wx.OK | wx.ICON_INFORMATION)
			dlg.ShowModal()
			dlg.Destroy()
	#----------------------------------------------------------------------
	def	onQuit(self,event):
		self.Unbind(wx.EVT_IDLE)
		self.ser.write('s'.encode('utf-8')) # stop Uno data stream
		print("Quitting...")
		self.Destroy()
####----------------------------------------------------------------------
####
#### Communications with Arduino Uno
####
####----------------------------------------------------------------------
	def ConnectToUno(self):
		UnoPID = 0x0043
		noUno=True
		self.unoPort = 'None'
		for pinfo in serial.tools.list_ports.comports():
			if (pinfo.pid==UnoPID):
				Device = 'Uno'
				self.unoPort = pinfo.device
				noUno=False
				break
		if (noUno):
			wx.MessageBox(\
			    'Unable to find an Arduino Uno. Is it connected?',\
				'Error:',wx.OK|wx.ICON_ERROR)
			sys.exit('Error: No Arduino Uno found!')
		while True:
			try:
				self.ser = serial.Serial(port=self.unoPort, baudrate = 250000,\
					timeout = 3)
				break
			except serial.SerialException:
				print("Waiting for USB port...");
				wx.MessageBox(\
				'Waiting for USB port...\n'+\
				'Is the Serial Monitor open on the Arduino app?',\
				'WARNING:',wx.OK|wx.ICON_NONE)
		# reset Uno
		self.ser.dtr=False;
		self.ser.reset_input_buffer()
		self.ClearBuffer()
		self.ser.dtr=True; # this will reset the Uno and restart program
		print("Waiting for Arduino to start:")
###		self.ser.write('?') 		# Get Uno program ID				
		ch = self.ser.read(3)[0:3]
		print("ch = *"+ch.decode()+"*")
		if (ch.decode() == "CNT"):
			print("Uno Counting program ready...")
		else:
			print("Uno counting program not found!");
			wx.MessageBox('Uno counting program not found\n'+\
							'Reload the program and try again',\
							'WARNING:',wx.CANCEL|wx.ICON_ERROR)
			sys.exit("Uno counting program not found! -- Quitting")
# 		ch = self.ser.read(1)
# 		while (ch <> 'C'):
# 		    ch = self.ser.read(1)
		#print "Uno ready."
		self.ser.write('s'.encode('utf-8')) ## make sure stopped
		self.unoMsg = "Connected to UNO on port: "+self.unoPort
		#self.unoPort = unoPort
		print(self.unoMsg)
	#----------------------------------------------------------------------
	#----------------------------------------------------------------------
	def ClearBuffer(self):
		self.ser.reset_input_buffer()
		# clear the data buffer:
		buf = self.ser.inWaiting()
		#print buf
		while (buf>0):
			ch = self.ser.read(buf)
			buf = self.ser.inWaiting()
			#print buf

####----------------------------------------------------------------------
####
#### Main program
####
####----------------------------------------------------------------------
app = wx.App(False)
w,h = wx.GetDisplaySize()
frame = MainWindow( None, "Nuclear Counting", (10,25), (300,725) )
app.MainLoop()
