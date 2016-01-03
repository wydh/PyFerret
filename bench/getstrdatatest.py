# To be run in python after importing and starting pyferret
# such as from running "pyferret -python"

import sys ; sys.ps1 = '' ; sys.ps2 = ''
print

print '>>> pyferret.run(\'let strarr = {"one", "two", "three", "four", "five", "six"}\')'
pyferret.run('let strarr = {"one", "two", "three", "four", "five", "six"}')
print ">>> pyferret.run('list strarr')"
pyferret.run('list strarr')
print ">>> strdict = pyferret.getstrdata('strarr')"
strdict = pyferret.getstrdata('strarr')
print ">>> print pyferret.metastr(strdict)"
print pyferret.metastr(strdict)
print ">>> strdata = strdict['data']"
strdata = strdict['data']
print ">>> repr(strdata.squeeze())"
repr(strdata.squeeze())
print ">>> del strdata"
del strdata
print ">>> del strdict"
del strdict
print ">>> strdict = pyferret.getstrdata('strarr')"
strdict = pyferret.getstrdata('strarr')
print ">>> repr(strdict)"
repr(strdict)
print ">>> del strdict"
del strdict

