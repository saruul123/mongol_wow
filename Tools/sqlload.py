import re
def load(path,name):
    s=open(path,encoding='utf8',errors='replace').read()
    m=re.search(r"CREATE TABLE `%s` \((.*?)\) ENGINE"%name,s,re.S)
    cols=[re.match(r"\s*`([^`]+)`",l).group(1) for l in m.group(1).split('\n') if re.match(r"\s*`",l)]
    rows=[]
    for m in re.finditer(r"INSERT INTO `%s` VALUES\s*"%name,s):
        pos=m.end()
        while True:
            assert s[pos]=='('; pos+=1; vals=[]
            while True:
                c=s[pos]
                if c=="'":
                    pos+=1; buf=[]
                    while True:
                        ch=s[pos]
                        if ch=='\\':
                            n=s[pos+1]; buf.append({'n':'\n','r':'\r','t':'\t','0':'\0'}.get(n,n)); pos+=2
                        elif ch=="'":
                            if s[pos+1]=="'": buf.append("'"); pos+=2
                            else: pos+=1; break
                        else: buf.append(ch); pos+=1
                    vals.append(''.join(buf))
                else:
                    e=pos
                    while s[e] not in ',)': e+=1
                    t=s[pos:e].strip(); vals.append(None if t.upper()=='NULL' else t); pos=e
                if s[pos]==',': pos+=1; continue
                if s[pos]==')': pos+=1; break
            rows.append(dict(zip(cols,vals)))
            if s[pos]==',':
                pos+=1
                while s[pos] in ' \r\n\t': pos+=1
                continue
            break
    return rows
