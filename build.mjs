// Bundles the original Abyss UI; the original user logo downloads from GitHub.
import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';
import {fileURLToPath} from 'node:url';
const root=path.dirname(fileURLToPath(import.meta.url));
const crcTable=Array.from({length:256},(_,n)=>{for(let i=0;i<8;i++)n=n&1?0xedb88320^(n>>>1):n>>>1;return n>>>0;});
function chunk(type,bytes){const body=Buffer.concat([Buffer.from(type),bytes]);let crc=0xffffffff;for(const byte of body)crc=crcTable[(crc^byte)&255]^(crc>>>8);const size=Buffer.alloc(4),checksum=Buffer.alloc(4);size.writeUInt32BE(bytes.length);checksum.writeUInt32BE((crc^0xffffffff)>>>0);return Buffer.concat([size,body,checksum]);}
function png(w,h,pixel){const rows=Buffer.alloc((w*4+1)*h);for(let y=0;y<h;y++)for(let x=0;x<w;x++)Buffer.from(pixel(x/(w-1),y/(h-1)).map(Math.round)).copy(rows,y*(w*4+1)+1+x*4);const header=Buffer.alloc(13);header.writeUInt32BE(w);header.writeUInt32BE(h,4);header[8]=8;header[9]=6;return Buffer.concat([Buffer.from('89504e470d0a1a0a','hex'),chunk('IHDR',header),chunk('IDAT',zlib.deflateSync(rows)),chunk('IEND',Buffer.alloc(0))]);}
// Replace missing upstream texture URLs with small deterministic UI textures.
const textures={
 'Gradient.png':png(2,64,(_,y)=>[0,0,0,y*72]),
 'Hue.png':png(2,256,(_,y)=>{const n=y*6,c=255,x=(1-Math.abs(n%2-1))*255;return [...(n<1?[c,x,0]:n<2?[x,c,0]:n<3?[0,c,x]:n<4?[0,x,c]:n<5?[x,0,c]:[c,0,x]),255];}),
 'Saturation.png':png(128,128,(x,y)=>{const a=1-x*(1-y);const c=a===0?0:(1-x)*(1-y)/a*255;return [c,c,c,a*255];}),
 'HueCursor.png':png(9,9,(x,y)=>{const d=Math.hypot(x-.5,y-.5);return d>.5||d<.24?[0,0,0,0]:d>.4?[0,0,0,255]:[255,255,255,255];})
};
let boot=`-- neoperroTFS: original Abyss Drawing layout, UI-only demo.
local Previous = getgenv().NeoperroTFS
if Previous and Previous.Destroy then Previous:Destroy() end
local function decodeBase64(Input)
    local Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local Lookup, Output, Accumulator, Bits = {}, {}, 0, 0
    for Index = 1, #Alphabet do Lookup[Alphabet:sub(Index, Index)] = Index - 1 end
    for Index = 1, #Input do
        local Value = Lookup[Input:sub(Index, Index)]
        if Value then
            Accumulator = Accumulator * 64 + Value
            Bits += 6
            if Bits >= 8 then
                Bits -= 8
                local Divisor = 2 ^ Bits
                table.insert(Output, string.char(math.floor(Accumulator / Divisor)))
                Accumulator %= Divisor
            end
        end
    end
    return table.concat(Output)
end
-- Exact original PNG. No cropping, recoloring, regeneration or image conversion.
local LogoURL = "https://raw.githubusercontent.com/kasztingers11-lang/neoperroTFS/main/assets/logo.png"
local LogoData = game:HttpGet(LogoURL)
assert(LogoData:sub(1, 8) == string.char(137,80,78,71,13,10,26,10), "Logo download did not return a PNG")
local EmbeddedAssets = {}
`;
for(const [name,data] of Object.entries(textures)){fs.writeFileSync(path.join(root,'assets',name),data);boot+=`EmbeddedAssets["${name}"] = decodeBase64([[${data.toString('base64')}]])\n`;}
const read=name=>fs.readFileSync(path.join(root,name),'utf8');
const bundle=boot+'\nlocal Library = (function()\n'+read('src/Library.luau')+'\nend)()\n\n'+read('src/App.luau');
fs.mkdirSync(path.join(root,'dist'),{recursive:true});
fs.writeFileSync(path.join(root,'dist/neoperroTFS.luau'),bundle);
console.log({lines:bundle.split('\n').length,bytes:Buffer.byteLength(bundle)});
