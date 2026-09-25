usage:
	ps -p $(pgrep -d',' run) -o %cpu,%mem

trace:
	strace -c zig build run > /dev/null

top:
	top -pid $(pgrep -d',' run)

clean:
	rm -rf .zig-cache zig-out zig-pkg
	
release:
	zig build --release=fast

release-prod:
	zig build --release=safe --summary all

log:
	git log --pretty=format:"%h%x09%an%x09%ad%x09%s"
