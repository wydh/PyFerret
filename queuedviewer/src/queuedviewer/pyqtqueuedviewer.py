import sip
sip.setapi('QVariant', 2)

from PyQt4.QtCore import QPointF, QTimer
from PyQt4.QtGui import QAction, QApplication, QBrush, QDialog, QFileDialog, \
                        QFont, QGraphicsScene, QGraphicsView, QImage, \
                        QMainWindow, QMessageBox, QPen, QPainter, QPolygonF, \
                        QPushButton
from pyqtqueuecmndhelper import PyQtQueueCmndHelper
from multiprocessing import Process
from Queue import Empty
import math
import sys


class PyQtQueuedViewer(QMainWindow):
    '''
    A PyQt graphics viewer that receives generic drawing commands through a queue.

    A drawing command is a dictionary with string keys that will be interpreted
    into the appropriate PyQt command(s).  For example,
      { "action":"drawText", "text":"Hello", 
        "font":{"family":"Times", "size":36, "italic":True},
        "fill":{color:"darkred"}, "outline":{color:"black"},
        "location":(25,35) }

    The command { "action":"exit" } will shutdown the viewer and is the only way
    the viewer can be closed.  GUI actions can only hide the viewer.    
    '''

    def __init__(self, cmndQueue):
        '''
        Create a PyQt viewer with with given command queue.
        '''
        QMainWindow.__init__(self)
        self.__queue = cmndQueue
        self.__scene = QGraphicsScene(self)
        self.__view = QGraphicsView(self.__scene, self)
        self.setCentralWidget(self.__view)
        self.createActions()
        self.createMenus()
        self.__gritems = { }
        self.__lastfilename = ""
        self.__shuttingdown = False
        self.__timer = QTimer(self)
        self.__timer.timeout.connect(self.checkCommandQueue)
        self.__timer.setInterval(0)
        self.__timer.start()

    def createActions(self):
        '''
        Create the actions used by the menus in this viewer.  Ownership
        of the actions are not transferred in addAction, thus the need
        to maintain references here.
        '''
        self.__saveAct = QAction("&Save", self, shortcut="Ctrl+S",
                                 statusTip="Save the current scene",
                                 triggered=self.inquireSaveFilename)
        self.__refreshAct = QAction("Re&fresh", self, shortcut="Ctrl+F",
                                    statusTip="Refresh the current scene",
                                    triggered=self.refreshScene)
        self.__resizeAct = QAction("&Resize", self, shortcut="Ctrl+R",
                                   statusTip="Resize the underlying scene",
                                   triggered=self.inquireResizeScene)
        self.__hideAct = QAction("&Hide", self, shortcut="Ctrl+H",
                                 statusTip="Hide the viewer",
                                 triggered=self.hide)
        self.__aboutAct = QAction("&About", self,
                                  statusTip="Show information about this viewer", 
                                  triggered=self.aboutMsg)
        self.__aboutQtAct = QAction("About &Qt", self,
                                    statusTip="Show information about the Qt library",
                                    triggered=self.aboutQtMsg)
        self.__exitAct = QAction("E&xit", self, 
                                 statusTip="Shut down the viewer",
                                 triggered=self.exitViewer)

    def createMenus(self):
        '''
        Create the menu items for the viewer 
        using the previously created actions.
        '''
        sceneMenu = self.menuBar().addMenu("&Scene")
        sceneMenu.addAction(self.__saveAct)
        sceneMenu.addAction(self.__refreshAct)
        sceneMenu.addAction(self.__resizeAct)
        sceneMenu.addSeparator()
        sceneMenu.addAction(self.__hideAct)
        helpMenu = self.menuBar().addMenu("&Help")
        helpMenu.addAction(self.__aboutAct)
        helpMenu.addAction(self.__aboutQtAct)
        helpMenu.addSeparator()
        helpMenu.addAction(self.__exitAct)

    def closeEvent(self, event):
        '''
        Override so the viewer cannot be closed from user GUI actions;
        instead only hide the window.  The viewer can only be closed
        by sending the {"action":"exit"} command to the queue.
        '''
        if self.__shuttingdown:
            event.accept()
        else:
            event.ignore()
            self.hide()

    def exitViewer(self):
        '''
        Close and exit the viewer
        '''
        self.__timer.stop()
        self.__shuttingdown = True
        self.close()

    def aboutMsg(self):
        QMessageBox.about(self, "About PyQtQueuedViewer",
            "\n" \
            "PyQtQueuedViewer is a graphics viewer application that " \
            "receives its drawing and other commands primarily from " \
            "another application through a queue.  A limited number " \
            "of commands are provided by the viewer itself to allow " \
            "saving and some manipulation of the displayed scene.  " \
            "The controlling application, however, will be unaware " \
            "of these modifications made to the scene. " \
            "\n\n" \
            "Normally, the controlling program will exit the viewer " \
            "when it is no longer needed.  The Help -> Exit menu item " \
            "should not normally be used.  It is provided when problems " \
            "occur and the controlling program cannot shut down the " \
            "viewer properly. " \
            "\n\n" \
            "PyQtViewer was developed by the Thermal Modeling and Analysis " \
            "Project (TMAP) of the National Oceanographic and Atmospheric " \
            "Administration's (NOAA) Pacific Marine Environmental Lab (PMEL). ")

    def aboutQtMsg(self):
        QMessageBox.aboutQt(self, "About Qt")

    def refreshScene(self):
        '''
        Refresh the current scene
        '''
        self.__scene.update(self.__scene.sceneRect())

    def inquireResizeScene(self):
        '''
        Prompt the user for the desired origin and size 
        of the underlying scene.
        
        Short-circuited to call resizeScene(0,0,400,400)
        '''
        self.resizeScene(0, 0, 400, 400)

    def resizeScene(self, x, y, width, height):
        '''
        Resize the underlying graphics scene to the given width and 
        height, with the upper left corner located at the coordinate
        (x, y).  If width or height is less than one, the upper-left
        corner will be set to (0, 0) and the scene size will be set
        to the size of the bounding rectangle of all the currently
        drawn items. 
        '''
        if (width < 1.0) or (height < 1.0):
            self.__scene.setSceneRect(self.__scene.itemsBoundingRect())
        else:
            self.__scene.setSceneRect(x, y, width, height)

    def resizeViewer(self, width, height):
        '''
        Resize the viewer (the QMainWindow) to the given width and
        height.  If width or height is less than one, the viewer is
        resized to slightly larger than the required width and height
        to show all the underlying graphics scene.
        '''
        if (width < 1.0) or (height < 1.0):
            scenerect = self.__scene.sceneRect()
            menuheight = self.menuBar().size().height()
            vwidth = int(scenerect.width() + 0.5 * menuheight)
            vheight = int(scenerect.height() + 1.5 * menuheight)
        else:
            vwidth = int(math.ceil(width) + 0.25)
            vheight = int(math.ceil(height) + 0.25)
        self.resize(vwidth, vheight)

    def inquireSaveFilename(self):
        '''
        Prompt the user for the name of the file into which to save the scene.
        The file format will be determined from the filename extension.
        '''
        formatTypes = ( ( "png", "Portable Networks Graphics (*.png)" ),
                        ( "jpeg", "Joint Photographic Experts Group (*.jpeg *.jpg *.jpe)" ),
                        ( "tiff", "Tagged Image File Format (*.tiff *.tif)" ),
                        ( "ppm", "Portable Pixmap (*.ppm)" ),
                        ( "xpm", "X11 Pixmap (*.xpm)" ),
                        ( "xbm", "X11 Bitmap (*.xbm)" ),
                        ( "bmp", "Windows Bitmap (*.bmp)" ), )
        filters = ";;".join([ t[1] for t in formatTypes ])
        (fileName, fileFilter) = QFileDialog.getSaveFileNameAndFilter(self, 
                                            "Save the current scene as ", 
                                            self.__lastfilename, filters)
        for (fmt, fmtName) in formatTypes:
            if fileFilter == fmtName:
                fileFormat = fmt
                break
        else:
            raise RuntimeError("Unexpected file format name %s" % fileFilter)
        if fileName:
            self.saveSceneToFile(fileName, fileFormat)
            self.__lastfilename = fileName

    def saveSceneToFile(self, fileName, imageFormat=None):
        '''
        Save the current scene to the named file.  If imageFormat is None,
        the format is guessed from the filename extension.
        '''
        sceneRect = self.__scene.sceneRect()
        image = QImage(sceneRect.width(), sceneRect.height(), QImage.Format_ARGB32)
        # Initialize the image by filling it with transparent white
        image.fill(0x00FFFFFF)
        painter = QPainter(image)
        self.__scene.render(painter)
        painter.end()
        image.save(fileName, imageFormat)

    def checkCommandQueue(self):
        '''
        Check the queue for a command.  If there are any, get and 
        perform one command only, then return.
        '''
        try:
            cmnd = self.__queue.get_nowait()
            try:
                self.processCommand(cmnd)
            finally:
                self.__queue.task_done()
        except Empty:
            pass

    def processCommand(self, cmnd):
        '''
        Examine the action of cmnd and call the appropriate 
        method to deal with this command.  Raises a KeyError
        if the "action" key is missing.
        '''
        cmndact = cmnd["action"]
        if cmndact == "exit":
            self.exitViewer()
        elif cmndact == "hide":
            self.hide()
        elif cmndact == "clear":
            self.clearScene()
        elif cmndact == "refresh":
            self.refreshScene()
        elif cmndact == "resizeScene":
            myrect = PyQtQueueCmndHelper.getRect(cmnd)
            self.resizeScene(myrect.x(), myrect.y(),
                             myrect.width(), myrect.height())
        elif cmndact == "resizeViewer":
            myrect = PyQtQueueCmndHelper.getRect(cmnd)
            self.resizeViewer(myrect.width(), myrect.height())
        elif cmndact == "save":
            self.saveScene()
        elif cmndact == "show":
            self.show()
        elif cmndact == "addPolygon":
            self.addPolygon(cmnd)
        elif cmndact == "addText":
            self.addSimpleText(cmnd)
        else:
            raise ValueError("Unknown command action %s" % str(cmndact))

    def clearScene(self):
        '''
        Removes all graphical items from the scene, leaving an empty scene.
        '''
        self.__scene.clear()
        self.__gritems = { }

    def saveScene(self, cmnd):
        '''
        Save the current scene to file.  Raises a KeyError if the
        "filename" key is not given.  The file format is guessed
        from the filename extension.
        '''
        fileName = cmnd["filename"]
        self.saveSceneToFile(fileName)

    def addSimpleText(self, cmnd):
        '''
        Add a "simple" text item to the viewer.  Raises a KeyError if either
        the "text" or "id" key is not given.

        Recognized keys from cmnd:
            "id": identification string for this graphics item
            "text": string to displayed
            "font": dictionary describing the font to use; 
                    see PyQtQueueCmndHelper.getFontFromCommand
            "fill": dictionary describing the brush used to draw the text; 
                    see PyQtQueueCmndHelper.getBrushFromCommand
            "outline": dictionary describing the pen used to outline the text; 
                       see PyQtQueueCmndHelper.getPenFromCommand
            "location": (x,y) location for the start of text in pixels 
                        from the upper left corner of the scene
        '''
        myid = cmnd["id"]
        # If this is a new ID, create an empty list of graphics items
        # associated with this ID.
        if self.__gritems.get(myid) == None:
            self.__gritems[myid] = [ ]
        # Create the simple text graphics item
        try:
            myfont = PyQtQueueCmndHelper.getFontFromCommand(cmnd, "font")
        except KeyError:
            myfont = QFont()
        mygrtext = self.__scene.addSimpleText(cmnd["text"], myfont)
        try:
            mybrush = PyQtQueueCmndHelper.getBrushFromCommand(cmnd, "fill")
            mygrtext.setBrush(mybrush)
        except KeyError:
            pass
        try:
            mypen = PyQtQueueCmndHelper.getPenFromCommand(cmnd, "outline")
            mygrtext.setPen(mypen)
        except KeyError:
            pass
        try:
            (x, y) = cmnd["location"] 
            mygrtext.translate(x, y)
        except KeyError:
            pass
        # Add this graphics item to list associated with the given ID
        self.__gritems[myid].append(mygrtext)

    def addPolygon(self, cmnd):
        '''
        Adds a polygon item to the viewer.  Raises a KeyError if either
        the "points" or the "id" key is not given.

        Recognized keys from cmnd:
            "id": identification string for this graphics item
            "points": the vertices of the polygon as a list of (x,y) points
                      of pixel values from the upper left corner of the scene
            "fill": dictionary describing the brush used to fill the polygon; 
                    see PyQtQueueCmndHelper.getBrushFromCommand
            "outline": dictionary describing the pen used to outline the polygon; 
                       see PyQtQueueCmndHelper.getPenFromCommand
            "offset": (x,y) offset, in pixels from the upper left corner of 
                      the scene, for the polygon
        '''
        myid = cmnd["id"]
        # If this is a new ID, create an empty list of graphics items
        # associated with this ID.
        if self.__gritems.get(myid) == None:
            self.__gritems[myid] = [ ]
        # Create the polygon graphics item
        mypoints = cmnd["points"]
        mypolygon = QPolygonF([ QPointF(x,y) for (x,y) in mypoints ])
        try:
            (x, y) = cmnd["offset"]
            mypolygon.translate(x, y)
        except KeyError:
            pass
        try:
            mypen = PyQtQueueCmndHelper.getPenFromCommand(cmnd, "outline")
        except KeyError:
            mypen = QPen()
        try:
            mybrush = PyQtQueueCmndHelper.getBrushFromCommand(cmnd, "fill")
        except KeyError:
            mybrush = QBrush()
        mygrpolygon = self.__scene.addPolygon(mypolygon, mypen, mybrush)
        # Add this graphics item to list associated with the given ID
        self.__gritems[myid].append(mygrpolygon)


class PyQtQueuedViewerProcess(Process):
    def __init__(self, joinablequeue):
        Process.__init__(self)
        self.__queue = joinablequeue

    def run(self):
        self.__app = QApplication(["PyQtQueuedViewer"])
        self.__viewer = PyQtQueuedViewer(self.__queue)
        result = self.__app.exec_()
        self.__queue.close()
        self.__queue.join()
        SystemExit(result)


class _PyQtCommandQueuer(QDialog):
    '''
    Testing dialog for controlling the addition of commands to a queue.
    Used for testing PyQtQueuedViewer in the same process as the viewer. 
    '''
    def __init__(self, parent, queue, cmndlist):
        QDialog.__init__(self, parent)
        self.__cmndlist = cmndlist
        self.__queue = queue
        self.__nextcmnd = 0
        self.__button = QPushButton("Queue next command", self)
        self.__button.pressed.connect(self.queueNextCommand)
        self.show()

    def queueNextCommand(self):
        try:
            self.__queue.put(self.__cmndlist[self.__nextcmnd])
            self.__nextcmnd += 1
        except IndexError:
            self.__queue.close()
            self.__queue.join()
            self.close()


if __name__ == "__main__":
    from Queue import Queue
    
    app = QApplication(["PyQtQueuedViewer"])
    cmndqueue = Queue()
    viewer = PyQtQueuedViewer(cmndqueue)
    drawcmnds = []
    squarepts = ( (0, 0), (0, 200), (200, 200), (200, 0), (0, 0) )
    pentagonpts = ( ( 80.90,   0.00), (  0.00,  58.78), 
                   ( 30.90, 153.88), (130.90, 153.88), 
                   (161.80,  58.78), ( 80.90,   0.00) )
    drawcmnds.append( { "action":"show" } )
    drawcmnds.append( { "action":"resizeScene",
                        "x":-10,
                        "y":-10,
                        "width":300,
                        "height":300 } )
    drawcmnds.append( { "action":"resizeViewer",
                        "width":400,
                        "height":400 } )
    drawcmnds.append( { "action":"addPolygon", "id":"background",
                        "points":squarepts,
                        "fill":{"color":"black", "alpha":32},
                        "outline":{"color":"black", "alpha":32} } )
    drawcmnds.append( { "action":"addPolygon", "id":"pentagon", 
                        "points":pentagonpts, 
                        "fill":{"color":"lightblue"},
                        "outline":{"color":"black", "width": 5, "style":"dash"},
                        "offset":(24,24) } )
    drawcmnds.append( { "action":"addPolygon", "id":"background",
                        "points":squarepts,
                        "fill":{"color":"pink", "alpha":32},
                        "outline":{"color":"black", "alpha":32} } )
    drawcmnds.append( { "action":"addText", "id":"annotation",
                        "text":"Bye", 
                        "font":{"family":"Times", "size":42, "italic": True},
                        "fill":{"color":0x880000}, 
                        "location":(55,60) } )
    drawcmnds.append( { "action":"resizeScene" } )
    drawcmnds.append( { "action":"resizeViewer" } )
    drawcmnds.append( { "action":"exit" } )
    tester = _PyQtCommandQueuer(viewer, cmndqueue, drawcmnds)
    tester.show()
    result = app.exec_()
    if result != 0:
        sys.exit(result)