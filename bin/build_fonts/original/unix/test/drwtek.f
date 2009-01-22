	program drwmarks
	character val*3
	character text*30
	data text/'Plot Marks'/
	call rotate(-90.0)
	call pltype(1)
	call size(10.5,8.2)
	call scale(1.,1.,1.,0.,0.,-8.2)
	sze=.21
	call markh(sze)
c	call erase
	call opndev(.true.,.true.)
	im=0
	x=1.8+2*1.4-sze*10*0.5
	call symbol(x,8.0,0.0,sze,10,text)
	do 10 j=1,5
	do 20 i=1,18
	x=1.8+(j-1)*1.4
	y=7.5-i*0.4
	write(val,999)im
999	format(i2,'=')
	s=x-sze*3
	call symbol(s,y,0.0,sze,3,val)
	call plot(x+0.25,y+sze*0.5,0,0)
	call mark(im)
	im=im+1
	if(im.gt.88)goto 100
20	continue
10	continue
100	call clsdev(.true.,.true.)
	call exit
	end
