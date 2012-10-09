var ma = Math,
	si = ma.sin,
	ra = ma.random,
	perspective,
	size = 32,
	W = 0,
	H = 0,
	points = [],
	angle = 0,
	ter = false;
	setPoint = function(x,y,z,c){
		t = this;
		t.xp = x;
		t.yp = y;
		t.zp = z;
		t.x = t.y = t.z = 0;
		t.c = c;
		return t;
	},
	addSection = function(yy){
	if(~~(ra()*100)>90){(ter)?ter=false:ter=true;};
		for (xx=0; xx <size; xx++){	
			var x = -1100 + xx * 80,
				z = -110 + yy * 80,
				y = 100;
				
				(ter==true)?y-=ra()*40:y=y;
		    (ter)?col=[0,190,50]:col=[0,149,200];
			points[yy * size +xx] = new setPoint(x,y,z,col);	
		}
	}

with(c){
	with(style)width=(W=innerWidth-9)+"px",height=(H=innerHeight-25)+"px";
	perspective = c.height;
}
			
for (yy=0; yy <size; yy++) {
		addSection(yy);					
}

for(p in a){
	a[p[0]+(p[6]||'')]=a[p];
}

// render loop
setInterval(function () {
	 with(a) {
		fillStyle = "rgba(190,250,250,.3)"
		fc(0, 0, W, H)
	
		for (j=size-1; j >-1; j--) {
			for (i=size-1; i >-1; i--) {
				var point = points[j * size + i],
					px = point.xp,
					py = point.yp,
					pz = point.zp,
					color = point.c;
				if(points[j * size + i].c[1]!=190){angle+=.000009; points[j * size + i].yp +=  si(angle+i+j)};
				point.zp -=10;	
				scl = perspective / (perspective + pz);
				
					point.y = 64 + py * scl;
					point.x= 128 + px * scl;
				
				m(~~point.x,~~point.y);
					
				if(j<size-1&&i<size-1&&pz > -110){
					l(~~points[((j+1) * size)+i].x,~~points[((j+1) * size)+i].y);
					l(~~points[(j+1) * size+(i+1)].x,~~points[(j+1) * size+(i+1)].y);
					l(~~points[(j * size)+(i+1)].x,~~points[(j * size)+(i+1)].y);
				}
				
				l(~~point.x,~~point.y);			
				fillStyle = 'rgb(' + ~~(100-point.zp/25) + ',' + ~~(color[1]-point.zp/25) + ',' + ~~(color[2] - point.zp/25) + ')';
				f();
				ba();
			}
		}
		
		if(points[0].zp < -110){	
			points.splice(0,size);
			addSection(size-1);	
		}
	}	
}, 10);