local a={}local b={}local c={["\n"]="\\n",["\r"]="\\r",["\t"]="\\t",["\b"]="\\b",["\f"]="\\f",["\""]="\\\"",["\\"]="\\\\"}local function d(t)local e=0;for f,g in pairs(t)do if type(f)~="number"then return false elseif f>e then e=f end end;return e==#t end;local h={['\n']=true,['\r']=true,['\t']=true,[' ']=true,[',']=true,[':']=true}function b.removeWhite(i)while h[i:sub(1,1)]do i=i:sub(2)end;return i end;local function j(k,l,m,n)local i=""local function o(p)i=i..("\t"):rep(m)..p end;local function q(k,r,s,u,v)i=i..r;if l then i=i.."\n"m=m+1 end;for f,g in u(k)do o("")v(f,g)i=i..","if l then i=i.."\n"end end;if l then m=m-1 end;if i:sub(-2)==",\n"then i=i:sub(1,-3).."\n"elseif i:sub(-1)==","then i=i:sub(1,-2)end;o(s)end;if type(k)=="table"then assert(not n[k],"Cannot encode a table holding itself recursively")n[k]=true;if d(k)then q(k,"[","]",ipairs,function(f,g)i=i..j(g,l,m,n)end)else q(k,"{","}",pairs,function(f,g)assert(type(f)=="string","JSON object keys must be strings",2)i=i..j(f,l,m,n)i=i..(l and": "or":")..j(g,l,m,n)end)end elseif type(k)=="string"then i='"'..k:gsub("[%c\"\\]",c)..'"'elseif type(k)=="number"or type(k)=="boolean"then i=tostring(k)else error("JSON only supports arrays, objects, numbers, booleans, and strings",2)end;return i end;function b.encode(k)return j(k,false,0,{})end;function b.encodePretty(k)return j(k,true,0,{})end;local w={}for f,g in pairs(c)do w[g]=f end;function b.parseBoolean(i)if i:sub(1,4)=="true"then return true,b.removeWhite(i:sub(5))else return false,b.removeWhite(i:sub(6))end end;function b.parseNull(i)return nil,b.removeWhite(i:sub(5))end;local x={['e']=true,['E']=true,['+']=true,['-']=true,['.']=true}function b.parseNumber(i)local y=1;while x[i:sub(y,y)]or tonumber(i:sub(y,y))do y=y+1 end;local k=tonumber(i:sub(1,y-1))i=b.removeWhite(i:sub(y))return k,i end;function b.parseString(i)i=i:sub(2)local p=""while i:sub(1,1)~="\""do local z=i:sub(1,1)i=i:sub(2)assert(z~="\n","Unclosed string")if z=="\\"then local A=i:sub(1,1)i=i:sub(2)z=assert(w[z..A],"Invalid escape character")end;p=p..z end;return p,b.removeWhite(i:sub(2))end;function b.parseArray(i)i=b.removeWhite(i:sub(2))local k={}local y=1;while i:sub(1,1)~="]"do local g=nil;g,i=b.parseValue(i)k[y]=g;y=y+1;i=b.removeWhite(i)end;i=b.removeWhite(i:sub(2))return k,i end;function b.parseObject(i)i=b.removeWhite(i:sub(2))local k={}while i:sub(1,1)~="}"do local f,g=nil,nil;f,g,i=b.parseMember(i)k[f]=g;i=b.removeWhite(i)end;i=b.removeWhite(i:sub(2))return k,i end;function b.parseMember(i)local f=nil;f,i=b.parseValue(i)local k=nil;k,i=b.parseValue(i)return f,k,i end;function b.parseValue(i)local B=i:sub(1,1)if B=="{"then return b.parseObject(i)elseif B=="["then return b.parseArray(i)elseif tonumber(B)~=nil or x[B]then return b.parseNumber(i)elseif i:sub(1,4)=="true"or i:sub(1,5)=="false"then return b.parseBoolean(i)elseif B=="\""then return b.parseString(i)elseif i:sub(1,4)=="null"then return b.parseNull(i)end;return nil end;function b.decode(i)i=b.removeWhite(i)t=b.parseValue(i)return t end;function b.decodeFromFile(C)local D=assert(fs.open(C,"r"))local E=b.decode(D.readAll())D.close()return E end;local F="/etc/pack"local G=F.."/packages"local H=F.."/sources.list"local I=F.."/sources.list.d"local function J(K,L)local M={}local N=1;local O,P=K.find(K,L,N)while O do table.insert(M,K.sub(K,N,O-1))N=P+1;O,P=K.find(K,L,N)end;table.insert(M,K.sub(K,N))return M end;local function Q(R,C)local S=http.get(R)local D=fs.open(C,"w")D.write(S.readAll())D.close()S.close()end;function a.getSources()local T=io.open(H,"r")local U=T:read()local V={}while U do table.insert(V,J(U," "))U=T:read()end;return V end;function a.fetchSources(W)local V=a.getSources()if W then if term.isColor()then term.setTextColour(colors.lime)end;print("Fetching")if term.isColor()then term.setTextColour(colors.blue)end end;for X,Y in pairs(V)do if W then print(Y[1])end;Q(Y[2],I.."/"..Y[1])end;if W then term.setTextColour(colors.white)end end;function a.fixSources(W)if not fs.exists(H)then local Z=fs.open(H,"w")Z.write("pack https://raw.githubusercontent.com/Commandcracker/CC-pack/master/pack.json")Z.close()a.fetchSources(W)end end;function a.addSource(_,R,W)for X,Y in pairs(a.getSources())do if Y[1]==_ then printError("Namespace already exists")return end end;if not http.checkURL(R)then if W then printError("Bad url")end;return end;local D=fs.open(H,"a")D.write("\n".._.." "..R)D.close()if W then if term.isColor()then term.setTextColour(colors.lime)end;print("Added:")if term.isColor()then term.setTextColour(colours.lightGrey)end;print(_)if term.isColor()then term.setTextColour(colors.blue)end;print(R)term.setTextColour(colors.white)end;a.fetchSources(W)end;function a.loadPackage(C,a0)for X,a1 in pairs(fs.list(C))do if a1=="bin"or a1=="programs"then a0.setPath(a0.path()..":"..C.."/"..a1)elseif a1=="lib"or a1=="apis"then for X,a2 in pairs(fs.list(C.."/"..a1))do end elseif a1=="startup"or a1=="startup.lua"then if fs.isDir(C.."/"..a1)then for X,a3 in pairs(fs.list(C.."/"..a1))do a0.run(C.."/"..a1 .."/"..a3)end else a0.run(C.."/"..a1)end end end end;function a.loadPackages(a0)for X,a4 in pairs(fs.list(G))do for X,a5 in pairs(fs.list(G.."/"..a4))do a.loadPackage(G.."/"..a4 .."/"..a5,a0)end end end;function a.installPackage(a6,a7,a0)if term.isColor()then term.setTextColour(colors.lime)end;print("Downloading")if term.isColor()then term.setTextColour(colors.blue)end;for C,D in pairs(a7["files"])do print(G.."/"..a6 .."/"..C)Q(D["url"],G.."/"..a6 .."/"..C)end;term.setTextColour(colors.white)a.loadPackage(G.."/"..a6,a0)end;function a.isPackageInstalled(a6)return fs.exists(G.."/"..a6)end;function a.removePackage(a6)fs.delete(G.."/"..a6)end;function a.getPackages()local a8={}for X,Y in pairs(fs.list(I))do local a9=fs.open(I.."/"..Y,"r")a8[Y]=b.decode(a9.readAll())["packages"]a9.close()end;return a8 end;a.json=b;return a