#!/opt/local/bin/python
# Runs under MacOS, Python 2.7 + wxPython + numpy + matplotlib + PySerial
#
####----------------------------------------------------------------------
####
#### Python Pulse Height Analyzer
####	 Use with Arduino Uno program PHA.ino
####	   or with test program RandomData.ino
####
####----------------------------------------------------------------------

import wx
if (wx.__version__[0]=='4'):
	import wx.adv
import os
import matplotlib
matplotlib.use('WXAgg')
import matplotlib.figure as plt
from matplotlib.backends.backend_wxagg import FigureCanvasWxAgg as FigureCanvas
import numpy as np
import serial
import serial.tools.list_ports
import sys

####----------------------------------------------------------------------
####
#### Global Initialization
####
####----------------------------------------------------------------------
xxx = np.linspace(0,1023,1024)
yyy = np.zeros(1024,np.int)
ser = serial.Serial()

####----------------------------------------------------------------------
####
#### Main window class
####
####----------------------------------------------------------------------
class MainWindow(wx.Frame):
	def __init__(self, parent, title, position, size):
		global xxx,yyy
		################## Connect to Arduino Uno
		self.unoPort = 'None'
		self.unoMsg = 'No Uno Connected.'
		self.ConnectToUno()
		################## Create main window
		wx.Frame.__init__(self, parent, title=title, pos=position, size=size)
		#self.__close_callback = None
		self.Bind(wx.EVT_CLOSE,self.OnSave)
		################## create things
		self.CreateMenu()
		self.CreateGraphPanel()
		self.CreateButtonPanel()
		################## arrange things
		frame_box = wx.BoxSizer(wx.VERTICAL)
		frame_box.Add(self.panel, flag=wx.EXPAND,proportion=1,border=10)
		frame_box.Add(self.buttonpanel,flag=wx.ALIGN_RIGHT|wx.RIGHT,border=10)
		self.SetSizer(frame_box)
		self.Show()
		#self.ShowWithEffect(wx.SHOW_EFFECT_ROLL_TO_BOTTOM)
		self.Layout()
	#----------------------------------------------------------------------
	def CreateMenu(self):
		menubar = wx.MenuBar()
		filemenu = wx.Menu()
		self.aboutItem = filemenu.Append(wx.ID_ABOUT,'&About xPHA')
		filemenu.AppendSeparator()
		self.startItem = filemenu.Append(-1,"Start...\tCtrl+1")
		self.stopItem = filemenu.Append(-1,"Stop...\tCtrl+2")
		self.saveItem = filemenu.Append(-1,"Save...\tCtrl+3")
		self.quitItem = filemenu.Append(-1,'Quit...\tCtrl+4')
		menubar.Append(filemenu,"&File")
		self.SetMenuBar(menubar)
		self.Bind(wx.EVT_MENU, self.OnAboutBox, self.aboutItem)
		self.Bind(wx.EVT_MENU, self.OnStart, self.startItem)
		self.Bind(wx.EVT_MENU, self.OnStop, self.stopItem)
		self.Bind(wx.EVT_MENU, self.OnSave, self.saveItem)
		self.Bind(wx.EVT_MENU, self.OnQuit, self.quitItem)
		self.stopItem.Enable(False)
		self.saveItem.Enable(False)
	#----------------------------------------------------------------------
	def CreateGraphPanel(self):
		panel = wx.Panel(self)
		self.panel = panel
		self.figure = plt.Figure()
		self.axis = self.figure.add_subplot(111)
		self.figure.subplots_adjust \
			(left=0.055, right=0.975,top=0.98, bottom=0.075)
#			(left=0.05, right=0.975,top=0.98, bottom=0.05)
		self.figurepanel = FigureCanvas(self.panel,-1,self.figure)
		self.draw()
		graph_box = wx.BoxSizer(wx.HORIZONTAL)
		self.graph_box = graph_box
		graph_box.Add(self.figurepanel,flag=wx.EXPAND,proportion=1)
		self.panel.SetSizer(graph_box)
	#----------------------------------------------------------------------
	def CreateButtonPanel(self):
		buttonpanel = wx.Panel(self)
		self.startbutton = wx.Button(buttonpanel,label='Start',size=(90,30))
		self.stopbutton = wx.Button(buttonpanel,label='Stop',size=(90,30))
		self.savebutton = wx.Button(buttonpanel,label='Save',size=(90,30))
		self.quitbutton = wx.Button(buttonpanel,label='Quit',size=(110,30))
		self.startbutton.Bind(wx.EVT_BUTTON,self.OnStart)
		self.stopbutton.Bind(wx.EVT_BUTTON,self.OnStop)
		self.savebutton.Bind(wx.EVT_BUTTON,self.OnSave)
		self.quitbutton.Bind(wx.EVT_BUTTON,self.OnQuit)
		self.ts = wx.StaticText(buttonpanel,-1, \
			"Connected to UNO on port: "+self.unoPort,\
			size=(-1,30),style=wx.ALIGN_CENTER)
		self.buttonbox=wx.BoxSizer(wx.HORIZONTAL)
		self.buttonbox.Add(self.ts,flag=wx.EXPAND|wx.ALL,proportion=4)
		self.buttonbox.AddStretchSpacer(prop=100)
		self.buttonbox.Add(self.startbutton)
		self.buttonbox.Add(self.stopbutton)
		self.buttonbox.Add(self.savebutton)
		self.buttonbox.Add(self.quitbutton)
		self.buttonpanel = buttonpanel
		self.buttonpanel.SetSizer(self.buttonbox)
		self.Layout()
		self.startbutton.Enable()
		self.stopbutton.Disable()
		self.savebutton.Disable()
		self.quitbutton.Enable()
	#----------------------------------------------------------------------
	def OnStart (self,event):
		global xxx,yyy,remains
		#print "Starting..."
		yyy = np.zeros(1024,np.int)
		#### turn on the idle event to collect data
		self.Bind(wx.EVT_IDLE, self.OnIdle) # for data collection!
		self.draw()
		self.startbutton.Disable()
		self.stopbutton.Enable()
		self.savebutton.Disable()
		self.quitbutton.Disable()
		self.startItem.Enable(False)
		self.stopItem.Enable(True)
		self.saveItem.Enable(False)
		self.quitItem.Enable(False)
		#### Tell Uno to start collecting data
		print "Data collection started..."
		self.ser.write('g') # start data stream
		#print "Sent a 'g'."
		self.remains=''
	#----------------------------------------------------------------------
	def OnStop (self,event):
		#print "Stop Event"
		self.ser.write('s') # stop Uno data stream
		print "Data Collection stopped."
		#print "Sent a 's'."
		self.Unbind(wx.EVT_IDLE)
		self.startbutton.Enable()
		self.stopbutton.Disable()
		self.savebutton.Enable()
		self.quitbutton.Enable()
		self.startItem.Enable(True)
		self.stopItem.Enable(False)
		self.saveItem.Enable(True)
		self.quitItem.Enable(True)
		#print "Clearing input buffer..."
		self.ClearBuffer()
		#self.ser.close()
		self.draw()
	#----------------------------------------------------------------------
	def OnSave(self, event):
		#print "Save Event"
		#print "Data Collection stopped."
		self.Unbind(wx.EVT_IDLE)
		self.startbutton.Enable()
		self.stopbutton.Disable()
		self.savebutton.Enable()
		self.quitbutton.Enable()
		self.startItem.Enable(True)
		self.stopItem.Enable(False)
		self.saveItem.Enable(True)
		self.quitItem.Enable(True)
		dlg = wx.FileDialog(self, "Save data as...", \
				os.getcwd(), "", "*.txt", \
				style=wx.FD_SAVE|wx.FD_OVERWRITE_PROMPT)
		result = dlg.ShowModal()
		inFile = dlg.GetPath()
		dlg.Destroy()
		if result == wx.ID_OK:			#Save button was pressed
			print "Saving data to",inFile
			np.savetxt(inFile,yyy,fmt='%d')
			self.savebutton.Disable()
			self.saveItem.Enable(False)
			#self.Close(True)
			#self.Destroy()
		elif result == wx.ID_CANCEL:	#Cancel button was pressed
			print "Save data cancelled."
	#----------------------------------------------------------------------
	def OnQuit(self,event):
		self.Unbind(wx.EVT_IDLE)
		self.ser.write('s') # stop Uno data stream
		print "Quitting..."
		self.Destroy()
	#----------------------------------------------------------------------		
	def OnAboutBox(self,event):
		if wx.__version__[0]=='4':
			info = wx.adv.AboutDialogInfo()
		else:
			info = wx.AboutDialogInfo()
		info.SetName('xPHA')
		info.SetVersion('1.0.1',longVersion='1.00 Beta')
		info.SetDescription('Pulse Height Analyzer using an Arduino Uno')
		info.AddDeveloper('Dan Briotta\nFebruary, 2019')
		if wx.__version__[0]=='4':
			wx.adv.AboutBox(info)
		else:
			wx.AboutBox(info)
	#----------------------------------------------------------------------
	#----------------------------------------------------------------------
	def OnIdle(self,event): # this is where the data is gathered
		global yyy #, remains
		if self.ser.inWaiting()>0:
			ins = self.ser.read(self.ser.inWaiting())
			data = (self.remains + ins).split()
			#### check remains carried properly:
			#print "("+self.remains+")"+ins.split()[0]+"="+data[0]+","+data[1]
			if (ins[-1] <> "\n"):
				self.remains = data.pop()
			else:
				self.remains = ""
			#print len(data)
			for d in data:
				chan = int(d)
				if (chan>0) and (chan<1023):
					yyy[chan] += 1
			self.draw()
		event.RequestMore(True)
	#----------------------------------------------------------------------
	#----------------------------------------------------------------------
	def draw(self):
		self.axis.clear()
		self.axis.set_xlabel('Channel')
		self.axis.set_ylabel('Counts')
		self.axis.set_xlim((0,1024))
		ymax = np.amax(yyy)
		if (ymax<=50):
			ymax=50
		else:
			lx = np.log10(ymax)
			xp = np.trunc(lx)
			xf = np.power(10.0,lx-xp)
			xx = 2
			if (xf>2.0):
				xx+=3
			if (xf>5.0):
				xx+=5
			ymax = xx * np.power(10.0,xp)
		self.axis.set_ylim((0,ymax))
		self.theLine, = \
			   self.axis.plot(xxx,yyy,color='blue',drawstyle='steps-mid')
		self.figurepanel.draw()
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
				'Error:',wx.OK|wx.ICON_EXCLAMATION)#ICON_ERROR)
			sys.exit('Error: No Arduino Uno found!')
		while True:
			try:
				self.ser = serial.Serial(port=self.unoPort, baudrate = 250000,\
					timeout = 2)
				break
			except serial.SerialException:
				print("Waiting for USB port...");
				wx.MessageBox(\
				'Waiting for USB port...\n'+\
				'Is the Arduino app still open?',\
				'WARNING:',wx.OK|wx.ICON_NONE)
		##### Reset Uno and clear out any preexisting data
		#print "Restarting Arduino..."
		self.ser.dtr=False;
		self.ser.reset_input_buffer()
		self.ClearBuffer()
		self.ser.dtr=True; # this will reset the Uno and restart program
		print "Waiting for Arduino to start:"
###		self.ser.write('?') 		# Get Uno program ID				
		ch = self.ser.read(3)[0:3]
		print "ch = *"+ch+"*"
		if (ch == "PHA"):
			print("Uno PHA ready...")
		else:
			print("Uno PHA not found!");
			wx.MessageBox('Uno PHA program not found\n'+\
							'Reload the program and try again',\
							'WARNING:',wx.CANCEL|wx.ICON_ERROR)
			sys.exit("Uno PHA program not found! -- Quitting")
		self.ser.write('s') ## make sure stopped
		self.unoMsg = "Connected to UNO on port: "+self.unoPort
		#self.unoPort = unoPort
		print self.unoMsg
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
#### Main Program:
####
####----------------------------------------------------------------------
#print "wx version = ",wx.version()
app = wx.App(False)
w,h = wx.GetDisplaySize()
frame = MainWindow( None, "Pulse Height Analyzer", (10,25), (0.95*w,0.85*h) )
#frame = MainWindow( None, "Pulse Height Analyzer", (10,25), (0.45*w,0.45*h) )
app.MainLoop()
