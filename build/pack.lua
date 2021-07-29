local a={["\n"]="\\n",["\r"]="\\r",["\t"]="\\t",["\b"]="\\b",["\f"]="\\f",["\""]="\\\"",["\\"]="\\\\"}local function b(t)local c=0;for d,e in pairs(t)do if type(d)~="number"then return false elseif d>c then c=d end end;return c==#t end;local f={['\n']=true,['\r']=true,['\t']=true,[' ']=true,[',']=true,[':']=true}local function g(h)while f[h:sub(1,1)]do h=h:sub(2)end;return h end;local function i(j,k,l,m)local h=""local function n(o)h=h..("\t"):rep(l)..o end;local function p(j,q,r,s,u)h=h..q;if k then h=h.."\n"l=l+1 end;for d,e in s(j)do n("")u(d,e)h=h..","if k then h=h.."\n"end end;if k then l=l-1 end;if h:sub(-2)==",\n"then h=h:sub(1,-3).."\n"elseif h:sub(-1)==","then h=h:sub(1,-2)end;n(r)end;if type(j)=="table"then assert(not m[j],"Cannot encode a table holding itself recursively")m[j]=true;if b(j)then p(j,"[","]",ipairs,function(d,e)h=h..i(e,k,l,m)end)else p(j,"{","}",pairs,function(d,e)assert(type(d)=="string","JSON object keys must be strings",2)h=h..i(d,k,l,m)h=h..(k and": "or":")..i(e,k,l,m)end)end elseif type(j)=="string"then h='"'..j:gsub("[%c\"\\]",a)..'"'elseif type(j)=="number"or type(j)=="boolean"then h=tostring(j)else error("JSON only supports arrays, objects, numbers, booleans, and strings",2)end;return h end;local function v(j)return i(j,false,0,{})end;local function w(j)return i(j,true,0,{})end;local x={}for d,e in pairs(a)do x[e]=d end;local function y(h)if h:sub(1,4)=="true"then return true,g(h:sub(5))else return false,g(h:sub(6))end end;local function z(h)return nil,g(h:sub(5))end;local A={['e']=true,['E']=true,['+']=true,['-']=true,['.']=true}local function B(h)local C=1;while A[h:sub(C,C)]or tonumber(h:sub(C,C))do C=C+1 end;local j=tonumber(h:sub(1,C-1))h=g(h:sub(C))return j,h end;local function D(h)h=h:sub(2)local o=""while h:sub(1,1)~="\""do local E=h:sub(1,1)h=h:sub(2)assert(E~="\n","Unclosed string")if E=="\\"then local F=h:sub(1,1)h=h:sub(2)E=assert(x[E..F],"Invalid escape character")end;o=o..E end;return o,g(h:sub(2))end;local function G(h)h=g(h:sub(2))local j={}local C=1;while h:sub(1,1)~="]"do local e=nil;e,h=parseValue(h)j[C]=e;C=C+1;h=g(h)end;h=g(h:sub(2))return j,h end;local function H(h)h=g(h:sub(2))local j={}while h:sub(1,1)~="}"do local d,e=nil,nil;d,e,h=parseMember(h)j[d]=e;h=g(h)end;h=g(h:sub(2))return j,h end;function parseMember(h)local d=nil;d,h=parseValue(h)local j=nil;j,h=parseValue(h)return d,j,h end;function parseValue(h)local I=h:sub(1,1)if I=="{"then return H(h)elseif I=="["then return G(h)elseif tonumber(I)~=nil or A[I]then return B(h)elseif h:sub(1,4)=="true"or h:sub(1,5)=="false"then return y(h)elseif I=="\""then return D(h)elseif h:sub(1,4)=="null"then return z(h)end;return nil end;local function J(h)h=g(h)t=parseValue(h)return t end;local function K(L)local M=assert(fs.open(L,"r"))local N=J(M.readAll())M.close()return N end;local function O(string,P)local Q={}local R=1;local S,T=string.find(string,P,R)while S do table.insert(Q,string.sub(string,R,S-1))R=T+1;S,T=string.find(string,P,R)end;table.insert(Q,string.sub(string,R))return Q end;local function U()local V="/etc/pack/sources.list"local W=io.open(V,"r")if not W then fs.open(V,"w").close()W=io.open(V,"r")end;local X=W:read()local sources={}while X do table.insert(sources,O(X," "))X=W:read()end;return sources end;local function Y(Z)response=http.get(Z)response=response.readAll()response=J(response)print(response["url"])end;local function _()for d,e in pairs(U())do print(e[1])end end;local function a0(a1)if not a1[2]then printError("Usage: show <package>")return end;sources=U()for d,e in pairs(sources)do if e[1]==a1[2]then print("Package:",e[1])print("Url:",e[2])return end end;printError("Package not found")end;local function a2(a1)if not a1[2]then printError("Usage: show <package>")return end;sources=U()local a3=false;for d,e in pairs(sources)do if string.match(e[1],a1[2])then print(e[1])a3=true end end;if not a3 then printError("No matching packages found")end end;local a4={{"install","install packages"},{"show","show package details",a0},{"search","search in package descriptions",a2},{"remove","remove packages"},{"list","list packages based on package names",_}}local function a5()print("commands:")for a6,a7 in pairs(a4)do print("  "..a7[1].." - "..a7[2])end end;local a1={...}if#a1<=0 then print("Usage: pack <command>")a5()return end;for a6,a7 in pairs(a4)do if a1[1]==a7[1]then a7[3](a1)return end end;printError("Command not found!")a5()