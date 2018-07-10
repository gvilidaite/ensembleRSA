# filename: cm_graph_utility.py
# description: load in data from .mat file(s) and draw out confusion matrices
#   supports different label types and diagonal suppression
# author: Zachary Goodale-Pirkle
#TODO: add ability to have multiple CM's open at once
#=============================================
import scipy.io
import matplotlib
matplotlib.use("TkAgg")
from matplotlib import pyplot as plt
import numpy as np
from Tkinter import *
import Tkinter, Tkconstants, tkFileDialog, tkMessageBox


class Application(Frame):
    def createWidgets(self):
        #Quit button - takes a few clicks sometimes
        self.QUIT = Button(text = "Quit", command = self.quit)
        self.QUIT.pack({"side": "bottom"})
        #Button to choose files
        self.choose_dir = Button(text = "Choose File(s)", command = self.choose_files)
        self.choose_dir.pack({"side": "top"})
        #Button to draw CM's
        self.graph = Button(text = "Graph CM", command = self.graph_cm)
        self.graph.pack({"side": "top"})
        #Button to clear graphs and class variables
        self.clear = Button(text = "Clear All", command = self.clearAll)
        self.clear.pack({"side": "bottom"})
        #Check box to suppress diagonal of CM's
        self.suppress = BooleanVar()
        self.suppress.set(0)
        self.suppress_diag = Checkbutton(root,
            text="Suppress Diagonal",
            variable=self.suppress).pack({"side": "right"})
        #Radio Buttons to selected label type
        self.labels = BooleanVar()
        self.labels.set(1)
        self.exemplar = Radiobutton(root,
            text="Exemplar Labels",
            padx = 5,
            variable=self.labels,
            value=0).pack({"side": "left"})
        self.category = Radiobutton(root,
            text="Category Labels",
            padx = 5,
            variable=self.labels,
            value=1).pack({"side": "left"})

    #Clears all graphs and resets all class variables
    def clearAll(self):
        self.cm_list = None
        self.grand_cm_list = []
        plt.close('all')
        return

    #Opens a dialog for the user to choose files for graphing
    def choose_files(self):
        files = filename = tkFileDialog.askopenfilenames(
            initialdir = ".",title = "Select file",filetypes =  (("matlab files","*.mat"),("all files","*.*")))
        #Sets the class variable 'self.cm_list' to the CM's in the selected files
        self.cm_list = self.import_matlab_files(files)

    #Converts files and extracts confusion matrices
    def import_matlab_files(self, files):
        cm_list = []
        for file in files:
            cm = scipy.io.loadmat(file)
            cm_list.append(cm["CM"])
        return cm_list

    #Draws up the confusion matrices
    def graph_cm(self):
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
        c_map = 'coolwarm'
        for inx, matrix in enumerate(self.grand_cm_list):
            figure = plt.figure(inx+1)
            plt.imshow(matrix, c_map)
            plt.colorbar()

            #Provides category labels if that option is selected
            if(self.labels.get()):
                axis_labels = ['HB','HF','AB','AF','IN','IA']
                plt.xticks(np.arange(6),axis_labels)
                plt.yticks(np.arange(6),axis_labels)
        plt.show()

    #Initializes the GUI and class variables
    def __init__(self, master=None):
        Frame.__init__(self, master)
        self.cm_list = None
        self.grand_cm_list = []
        self.pack()
        self.createWidgets()

    # figure = plt.figure(1)
    # plt.imshow(grand_cm, c_map)
    # plt.colorbar()
    #
    # #Provides category labels if that option is selected
    # if(self.labels.get()):
    #     axis_labels = ['HB','HF','AB','AF','IN','IA']
    #     plt.xticks(np.arange(6),axis_labels)
    #     plt.yticks(np.arange(6),axis_labels)
    # self.plot_list.append(figure)
    # for figure in self.plot_list:
    #     figure.show()

root = Tk()
root.title("Confusion Matrix Graph Utility")
root.geometry("400x200")
app = Application(master=root)
app.mainloop()
root.destroy()
