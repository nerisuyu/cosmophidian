pico8 = 'C:\Program Files (x86)\PICO-8\pico8.exe'
export_name='\pico_build\\ass.html'
fullname=export
hello:
	echo "Hello, World"
bye:
	echo "Goodbye, World!"

bin:
	${pico8} -frameless export.p8