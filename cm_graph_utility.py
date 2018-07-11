# Filename: cm_graph_utility.py
# Description: load in data from .mat file(s) and draw out confusion matrices.
    # Supports different label types and diagonal suppression.
# Usage:
    # 1). Select File(s) by pressing "Choose File(s)" and navigating to the
    #    .mat file(s) containing the Confusion Matrices you want to graph.
    #    (NOTE: Program looks for key 'CM' in .mat data.)
    # 2). Select options for category labels and diagonal suppression.
    #    (DEFAULT: category labels & no suppression)
    # 3). OPTIONAL: Choose image file names to replace ticks on exemplar lableling.
    #        (Press button labeled "Image Name Exemplar Labeling" to do so)
    # 4). OPTIONAL: Check "Autosave Graphs" if you want the graphs to be automatically saved upon
    #        being drawn out. Make sure to select a directory to save the files to if this
    #        is the case. Files autosaved using the datetime as a filename.
    # 5.) OPTIONAL: Select a color map from the dropdown menu. 
    # 5). Press "Graph CM" to draw out confusion matrix.
    #       (NOTE: Applies current settings to all C.M.'s being drawn)
    # 6). Repeat to draw out more matrices. Utility will continue to draw out
    #       past matrices from current session until "Clear All" is hit, which
    #       will clear all graphs from the screen and memory.
    # 7). Press "Quit" to exit the program (may take a few clicks), or simply exit
    #       out of the screen.
# Author: Zachary Goodale-Pirkle
# TODO: Axis Labels as Images for exemplar
#=============================================
# NOTE: Make sure to install all neccessary Scipy files: https://www.scipy.org/install.html
#=============================================
#Scipy imports:
import scipy.io
import matplotlib
matplotlib.use("TkAgg")
from matplotlib import pyplot as plt
import matplotlib.image as mpimg
import pylab as pl
import numpy as np
#=============================================
#Tkinter GUI imports:
from Tkinter import *
import Tkinter, Tkconstants, tkFileDialog, tkMessageBox
#=============================================
#Misc imports:
import datetime
import os
#=============================================

class Application(Frame):
    def createWidgets(self):
        #Quit button - takes a few clicks sometimes
        self.QUIT = Button(text = "Quit",
            command = self.quit).pack({"side": "bottom"})
        #Button to choose files
        self.choose_dir = Button(text = "Choose .mat File(s)",
            command = self.choose_files).pack({"side": "top"})
        #Button to draw CM's
        self.graph = Button(text = "Graph CM",
            command = self.graph_cm).pack({"side": "top"})
        #Check box to select whether to autosave graphs
        self.save_graph = BooleanVar()
        self.save_graph.set(False)
        self.save = Checkbutton(root, text = "Autosave Graphs",
            variable = self.save_graph).pack({"side": "top"})
        #Button to select save directory
        self.save_dir = Button(root, text = "Choose Save Directory",
            command = self.choose_save_dir).pack({"side": "top"})
        #Button to clear graphs and class variables
        self.clear = Button(text = "Clear All",
            command = self.clearAll).pack({"side": "bottom"})
        #Button to choose image files for exemplar labeling
        self.img_labels = Button(text = "Image Name Exemplar Labeling",
            command = self.choose_img_files).pack({"side": "bottom"})
        #Dropdown menu to choose colormaps
        self.c_map = StringVar()
        color_options = {'coolwarm', 'viridis', 'plasma', 'Reds', 'Pastel1', 'cubehelix'}
        self.c_map.set('coolwarm')
        self.choose_color = OptionMenu(root, self.c_map,
            *color_options).pack({"side":"right"})
        #Check box to suppress diagonal of CM's
        self.suppress = BooleanVar()
        self.suppress.set(0)
        self.suppress_diag = Checkbutton(root, text="Suppress Diagonal",
            variable=self.suppress).pack({"side": "right"})
        #Radio Buttons to selecte label type
        self.labels = BooleanVar()
        self.labels.set(1)
        self.exemplar = Radiobutton(root, text="Exemplar Labels", padx = 5, variable=self.labels,
            value=0).pack({"side": "left"})
        self.category = Radiobutton(root, text="Category Labels", padx = 5, variable=self.labels,
            value=1).pack({"side": "left"})


    #Clears all graphs and resets most class variables
    def clearAll(self):
        self.cm_list = None
        self.img_list = []
        self.grand_cm_list = []
        plt.close('all')
        return

    def choose_save_dir(self):
        self.save_dir = tkFileDialog.askdirectory()
        return

    #Opens a dialog for the user to choose files for graphing
    def choose_files(self):
        files = tkFileDialog.askopenfilenames(
            initialdir = ".",title = "Select file",filetypes = (("matlab files","*.mat"),("all files","*.*")))
        #Sets the class variable 'self.cm_list' to the CM's in the selected files
        self.cm_list = self.import_matlab_files(files)
        return

    #Opens a dialog for the user to choose image file names as tick marks in exemplar CM's.
    def choose_img_files(self):
        files = tkFileDialog.askopenfilenames(
            initialdir = ".",title = "Select file",filetypes = (("jpeg files","*.jpg"),
                ("png files", "*.png"), ("all files","*.*")))
        for file in files:
            tail = file.split('/')
            self.img_list.append(tail[-1].split('.',1)[0])
        return

    #Converts files and extracts confusion matrices
    def import_matlab_files(self, files):
        cm_list = []
        for file in files:
            cm = scipy.io.loadmat(file)
            cm_list.append(cm["CM"])
        return cm_list

    #Draws up the confusion matrices
    def graph_cm(self):
        #Checks to see if a valid directory is selected to autosave to if autosave is enabled
        if(self.save_graph.get() and (not self.save_dir or not os.path.isdir(self.save_dir))):
            tkMessageBox.showerror("Error", "Please choose a valid directory to autosave to")
            return
        plt.close('all')
        #If no files have been selected a message box appears and method exits
        if(not self.cm_list):
            tkMessageBox.showerror("Error", "Please choose a file(s)")
            return
        cm_list = self.cm_list
        grand_cm = np.squeeze(np.mean(cm_list, 0))

        #Sets the diagonal to 0 if the user has selected suppress diagonal
        if(self.suppress.get()):
            np.fill_diagonal(grand_cm, 0)

        self.grand_cm_list.append(grand_cm)
        #More color maps at: http://matplotlib.org/examples/color/colormaps_reference.html
        c_map = self.c_map.get()
        #Iterates through all stored matrices and graphs them all out.
        #Uses a reverse for loop so the newest graphs appears first.
        for x in range(len(self.grand_cm_list)-1, -1, -1):
            figure = plt.figure(x+1)
            plt.imshow(self.grand_cm_list[x], c_map)
            plt.colorbar()

            #Provides category labels if that option is selected
            if(self.labels.get()):
                axis_labels = ['HB','HF','AB','AF','IN','IA']
                plt.xticks(np.arange(6),axis_labels)
                plt.yticks(np.arange(6),axis_labels)
            #Provides image names as examplar lables if image files are selected, otherwise
            #defaults to numbers. Could not implement actual images as ticks, no easy way to do so.
            else:
                if(self.img_list):
                    font_size = len(self.img_list)/3
                    plt.xticks(np.arange(len(self.img_list)), self.img_list, font_size)
                    plt.yticks(np.arange(len(self.img_list)), self.img_list, font_size)
            #If autosave is selected, new graphs will be saved (only the last one in the list)
            if (x == len(self.grand_cm_list)-1) and (self.save_graph.get()):
                #The filename is generated with the current date and time.
                date = datetime.datetime.today().strftime('%Y-%m-%d_%H_%M_%S')
                filename = 'Fig' + date
                plt.savefig(self.save_dir+ '/' +filename)
        plt.show()

    #Initializes the GUI and class variables
    def __init__(self, master=None):
        Frame.__init__(self, master)
        self.img_list = []
        self.cm_list = None
        self.grand_cm_list = []
        self.save_dir = None
        self.pack()
        self.createWidgets()

root = Tk()
root.title("Confusion Matrix Graph Utility")
root.geometry("600x300")
app = Application(master=root)
app.mainloop()
root.destroy()
