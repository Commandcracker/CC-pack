local a={["\n"]="\\n",["\r"]="\\r",["\t"]="\\t",["\b"]="\\b",["\f"]="\\f",["\""]="\\\"",["\\"]="\\\\"}local function b(t)local c=0;for d,e in pairs(t)do if type(d)~="number"then return false elseif d>c then c=d end end;return c==#t end;local f={['\n']=true,['\r']=true,['\t']=true,[' ']=true,[',']=true,[':']=true}local function g(h)while f[h:sub(1,1)]do h=h:sub(2)end;return h end;local function i(j,k,l,m)local h=""local function n(o)h=h..("\t"):rep(l)..o end;local function p(j,q,r,s,u)h=h..q;if k then h=h.."\n"l=l+1 end;for d,e in s(j)do n("")u(d,e)h=h..","if k then h=h.."\n"end end;if k then l=l-1 end;if h:sub(-2)==",\n"then h=h:sub(1,-3).."\n"elseif h:sub(-1)==","then h=h:sub(1,-2)end;n(r)end;if type(j)=="table"then assert(not m[j],"Cannot encode a table holding itself recursively")m[j]=true;if b(j)then p(j,"[","]",ipairs,function(d,e)h=h..i(e,k,l,m)end)else p(j,"{","}",pairs,function(d,e)assert(type(d)=="string","JSON object keys must be strings",2)h=h..i(d,k,l,m)h=h..(k and": "or":")..i(e,k,l,m)end)end elseif type(j)=="string"then h='"'..j:gsub("[%c\"\\]",a)..'"'elseif type(j)=="number"or type(j)=="boolean"then h=tostring(j)else error("JSON only supports arrays, objects, numbers, booleans, and strings",2)end;return h end;local function v(j)return i(j,false,0,{})end;local function w(j)return i(j,true,0,{})end;local x={}for d,e in pairs(a)do x[e]=d end;local function y(h)if h:sub(1,4)=="true"then return true,g(h:sub(5))else return false,g(h:sub(6))end end;local function z(h)return nil,g(h:sub(5))end;local A={['e']=true,['E']=true,['+']=true,['-']=true,['.']=true}local function B(h)local C=1;while A[h:sub(C,C)]or tonumber(h:sub(C,C))do C=C+1 end;local j=tonumber(h:sub(1,C-1))h=g(h:sub(C))return j,h end;local function D(h)h=h:sub(2)local o=""while h:sub(1,1)~="\""do local E=h:sub(1,1)h=h:sub(2)assert(E~="\n","Unclosed string")if E=="\\"then local F=h:sub(1,1)h=h:sub(2)E=assert(x[E..F],"Invalid escape character")end;o=o..E end;return o,g(h:sub(2))end;local function G(h)h=g(h:sub(2))local j={}local C=1;while h:sub(1,1)~="]"do local e=nil;e,h=parseValue(h)j[C]=e;C=C+1;h=g(h)end;h=g(h:sub(2))return j,h end;local function H(h)h=g(h:sub(2))local j={}while h:sub(1,1)~="}"do local d,e=nil,nil;d,e,h=parseMember(h)j[d]=e;h=g(h)end;h=g(h:sub(2))return j,h end;function parseMember(h)local d=nil;d,h=parseValue(h)local j=nil;j,h=parseValue(h)return d,j,h end;function parseValue(h)local I=h:sub(1,1)if I=="{"then return H(h)elseif I=="["then return G(h)elseif tonumber(I)~=nil or A[I]then return B(h)elseif h:sub(1,4)=="true"or h:sub(1,5)=="false"then return y(h)elseif I=="\""then return D(h)elseif h:sub(1,4)=="null"then return z(h)end;return nil end;local function J(h)h=g(h)t=parseValue(h)return t end;local function K(L)local file=assert(fs.open(L,"r"))local M=J(file.readAll())file.close()return M end;local function N(string,O)local P={}local Q=1;local R,S=string.find(string,O,Q)while R do table.insert(P,string.sub(string,Q,R-1))Q=S+1;R,S=string.find(string,O,Q)end;table.insert(P,string.sub(string,Q))return P end;local function T(U,L)response=http.get(U)response=response.readAll()file=fs.open(L,"w")file.write(response)file.close()end;local function V(V)if V==nil then else if term.isColor()then term.setTextColour(colors.orange)end;term.write(V.."? [")if term.isColor()then term.setTextColour(colors.lime)end;term.write('Y')if term.isColor()then term.setTextColour(colors.orange)end;term.write('/')if term.isColor()then term.setTextColour(colors.red)end;term.write('n')if term.isColor()then term.setTextColour(colors.orange)end;term.write("] ")term.setTextColour(colors.white)end;local W=string.lower(string.sub(read(),1,1))if W=='y'or W=='j'or W==''then return true else return false end end;local X="/etc/pack"local Y=X.."/sources.list"local Z=X.."/sources.list.d"local _=X.."/packages"local function a0()local a1=io.open(Y,"r")local a2=a1:read()local a3={}while a2 do table.insert(a3,N(a2," "))a2=a1:read()end;return a3 end;local function a4()local a3=a0()print("Fetching")for a5,a6 in pairs(a3)do print(a6[1])T(a6[2],Z.."/"..a6[1])end end;local function a7()packages={}for a5,a8 in pairs(fs.list(Z))do _f=fs.open(Z.."/"..a8,"r")packages[a8]=J(_f.readAll())_f.close()end;return packages end;local function a9(aa,ab)for d,e in pairs(ab["files"])do T(e,_.."/"..aa.."/"..d)end end;if not fs.exists(Y)then _f=fs.open(Y,"w")_f.write("pack https://raw.githubusercontent.com/Commandcracker/CC-pack/master/packages.json")_f.close()a4()end;local function ac()for a6,ad in pairs(a7())do for aa,a5 in pairs(ad)do print(a6 .."/"..aa)end end end;local function ae(af)if not af[2]then printError("Usage: show <package>")return end;for a6,ad in pairs(a7())do for aa,a8 in pairs(ad)do if aa==af[2]then print("Package:",aa)print("Url:",a8["url"])return end end end;printError("Package not found")end;local function ag(af)if not af[2]then printError("Usage: search <package>")return end;local ah=false;for a6,ad in pairs(a7())do for aa,a5 in pairs(ad)do if string.match(aa,af[2])then print(a6 .."/"..aa)ah=true end end end;if not ah then printError("No matching packages found")end end;local function ai(af)if not af[2]then printError("Usage: install <package>")return end;for a6,ad in pairs(a7())do for aa,a8 in pairs(ad)do if aa==af[2]then if V("install "..a6 .."/"..aa)then a9(a6 .."/"..aa,a8)end;return end end end;printError("Package not found")end;local aj={{"install","install packages",ai},{"show","show package details",ae},{"search","search in package descriptions",ag},{"remove","remove packages"},{"list","list packages based on package names",ac}}local function ak()print("commands:")for a5,al in pairs(aj)do print("  "..al[1].." - "..al[2])end end;local af={...}if#af<=0 then print("Usage: pack <command>")ak()return end;for a5,al in pairs(aj)do if af[1]==al[1]then al[3](af)return end end;printError("Command not found!")ak()