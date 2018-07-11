# filename: import_to_py.py
# description: load in data from .mat file(s) and graph confusion matrices
#=============================================

import scipy.io
import matplotlib.pyplot as plt
import numpy as np
import sys

def import_matlab_files(files):
	cm_list = []
	print files
	for file in files:
		cm = scipy.io.loadmat(file)
		cm_list.append(cm['CM'])
	return cm_list

def main(argv):
	cm_list = import_matlab_files(argv)
	grand_cm = np.squeeze(np.mean(cm_list, 0))

	# http://matplotlib.org/examples/color/colormaps_reference.html
	c_map = 'coolwarm'
	plt.imshow(grand_cm, c_map)
	plt.colorbar()
	axis_labels = ['HB', 'HF', 'AB', 'AF', 'IN', 'IA'];
	plt.xticks(np.arange(6),axis_labels)
	plt.yticks(np.arange(6),axis_labels)
	plt.show()




if __name__ == '__main__':
	main(sys.argv[1:])
