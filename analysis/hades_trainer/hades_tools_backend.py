from __future__ import annotations
import argparse,json,threading
from http.server import BaseHTTPRequestHandler,ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse
import frida,psutil

ROOT=Path(__file__).resolve().parent
PROFILE=json.loads((ROOT/'hades_runtime_profile.json').read_text())

def lua_quote(value):
    if value is None:return 'nil'
    if value is True:return 'true'
    if value is False:return 'false'
    if isinstance(value,(int,float)):return str(value)
    if isinstance(value,str):return '"'+value.replace('\\','\\\\').replace('"','\\"').replace('\n','\\n')+'"'
    if isinstance(value,list):return '{'+','.join(lua_quote(x) for x in value)+'}'
    if isinstance(value,dict):return '{'+','.join('['+lua_quote(str(k))+']='+lua_quote(v) for k,v in value.items())+'}'
    raise TypeError(type(value))

class Bridge:
    def __init__(self,pid):
        source=(ROOT/'hades_tools_runtime.js').read_text().replace('__PROFILE__',json.dumps(PROFILE))
        self.detached=threading.Event();self.detach_reason=None
        self.session=frida.attach(pid)
        self.session.on('detached',self.on_detached)
        self.script=self.session.create_script(source);self.script.load();self.exports=self.script.exports_sync
        self.pid=pid
    def on_detached(self,reason,crash):
        self.detach_reason=reason
        self.detached.set()
    def run(self,command):
        if self.detached.is_set():raise RuntimeError(f'Hades {self.pid} disconnected: {self.detach_reason}')
        source=(ROOT/'hades_tools_commands.lua').read_text()+'\nlocal ok,value=pcall(HADES_TOOLS.Command,'+lua_quote(command)+')\nif not ok then error(value) end\n'+(ROOT/'hades_tools_json.lua').read_text()+'\nreturn HadesToolsJson.encode(value)'
        return self.exports.evaluate(source,10000)
    def info(self):return self.exports.info()
    def native(self):return self.exports.native()

class App(BaseHTTPRequestHandler):
    bridge=None
    def send_json(self,status,payload):
        data=json.dumps(payload,ensure_ascii=False).encode();self.send_response(status);self.send_header('Content-Type','application/json; charset=utf-8');self.send_header('Content-Length',str(len(data)));self.end_headers();self.wfile.write(data)
    def do_GET(self):
        if urlparse(self.path).path=='/':
            data=(ROOT/'hades_tools_ui.html').read_bytes();self.send_response(200);self.send_header('Content-Type','text/html; charset=utf-8');self.send_header('Content-Length',str(len(data)));self.end_headers();self.wfile.write(data);return
        if urlparse(self.path).path=='/api/info':return self.send_json(200,self.bridge.info())
        if urlparse(self.path).path=='/api/native':return self.send_json(200,self.bridge.native())
        self.send_json(404,{'error':'not found'})
    def do_POST(self):
        if urlparse(self.path).path=='/api/shutdown':
            self.send_json(200,{'ok':True})
            threading.Thread(target=self.server.shutdown,daemon=True).start()
            return
        if urlparse(self.path).path!='/api/command':return self.send_json(404,{'error':'not found'})
        try:
            length=int(self.headers.get('Content-Length','0'));command=json.loads(self.rfile.read(length));self.send_json(200,{'ok':True,**self.bridge.run(command)})
        except Exception as e:self.send_json(400,{'ok':False,'error':str(e)})
    def log_message(self,fmt,*args):print('[HTTP]',fmt%args)

def find_hades():
    rows=[p.pid for p in psutil.process_iter(['name']) if p.info['name'] and p.info['name'].lower()=='hades.exe']
    if len(rows)!=1:raise RuntimeError(f'Expected exactly one Hades.exe, found {rows}')
    return rows[0]

def main():
    p=argparse.ArgumentParser();p.add_argument('--pid',type=int);p.add_argument('--host',default='127.0.0.1');p.add_argument('--port',type=int,default=27864);p.add_argument('--parent-pid',type=int);a=p.parse_args()
    App.bridge=Bridge(a.pid or find_hades())
    server=ThreadingHTTPServer((a.host,a.port),App)
    def watch_game():
        App.bridge.detached.wait()
        print(f'HADES_TOOLS_GAME_EXIT pid={App.bridge.pid} reason={App.bridge.detach_reason}',flush=True)
        server.shutdown()
    threading.Thread(target=watch_game,daemon=True).start()
    if a.parent_pid:
        parent=psutil.Process(a.parent_pid)
        def watch_parent():
            parent.wait()
            server.shutdown()
        threading.Thread(target=watch_parent,daemon=True).start()
    print(f'HADES_TOOLS_READY http://{a.host}:{a.port}',flush=True)
    try:
        server.serve_forever()
    finally:
        try:
            if not App.bridge.detached.is_set():
                try: print('HADES_TOOLS_CLEANUP '+json.dumps(App.bridge.run({'action':'session_end'})),flush=True)
                except Exception as error: print(f'Session cleanup: {error}',flush=True)
                try: App.bridge.session.detach()
                except frida.InvalidOperationError as error: print(f'Session detach: {error}',flush=True)
        finally:
            server.server_close()
if __name__=='__main__':main()
