# filename: import_to_py.py
# description: load in data from a .mat file
#=============================================

import scipy.io

	
def import_matlab_file(file):
	mat = scipy.io.loadmat(file)
	return mat 

def main(argv):
	mat = import_matlab_file(argv[0])
	print mat

if __name__ == '__main__':
	main(sys.argv[1:])

