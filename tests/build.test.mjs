import test, {before} from 'node:test';
import {stripLuauComments} from '../luau-source.mjs';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
import {createHash} from 'node:crypto';

const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const read=name=>fs.readFileSync(path.join(root,name));
const build=()=>{
  const result=spawnSync(process.execPath,['build.mjs'],{cwd:root,encoding:'utf8'});
  assert.equal(result.status,0,result.stderr);
};
let bundle;
before(()=>{build();bundle=read('dist/neoperroTFS.luau').toString('utf8');});

test('standalone bundle contains the exact supplied logo',()=>{
  const match=bundle.match(/local LogoData = decodeBase64\(\[\[([A-Za-z0-9+/=]+)\]\]\)/);
  assert.ok(match,'Embedded PNG missing');
  const embedded=Buffer.from(match[1],'base64');
  assert.deepEqual(embedded,read('assets/logo.png'));
  assert.equal(createHash('sha256').update(embedded).digest('hex'),
    '1e4d00f434d682b47f9f5f53e07890435f5f018610417e384c5f24db808e23c1');
  assert.equal(embedded.readUInt32BE(16),1254);
  assert.equal(embedded.readUInt32BE(20),1254);
});

test('all bundled UI textures match their PNG artifacts',()=>{
  const matches=[...bundle.matchAll(/EmbeddedAssets\["([^"]+)"\] = decodeBase64\(\[\[([A-Za-z0-9+/=]+)\]\]\)/g)];
  assert.equal(matches.length,5);
  for(const [,name,data] of matches) assert.deepEqual(Buffer.from(data,'base64'),read(`assets/${name}`));
});

test('distribution includes every current source module',()=>{
  for(const name of ['Library','Features','ShopAdapter','Navigation','AmmoAdapter','Automation','Visuals','App']){
    assert.ok(bundle.includes(read(`src/${name}.luau`).toString('utf8')),`${name} is missing or stale`);
  }
});

test('rebuilding produces identical standalone bytes',()=>{
  const before=read('dist/neoperroTFS.luau');
  build();
  assert.deepEqual(read('dist/neoperroTFS.luau'),before);
});

test('source and executable contain no Luau comments',()=>{
  for(const name of ['loader.luau',...fs.readdirSync(path.join(root,'src')).filter(x=>x.endsWith('.luau')).map(x=>'src/'+x),'dist/neoperroTFS.luau']){
    const source=read(name).toString('utf8');
    assert.equal(stripLuauComments(source),source,name);
  }
});

test('comment removal preserves strings, delimiters and token separation',()=>{
  const source = `local a="https://host/--path" -- remove
local b=[=[--literal\ncontents]=] --[==[remove\nblock]==]local c='--quoted'
return a--tail`;
  const result=stripLuauComments(source);
  assert.ok(result.includes('"https://host/--path"'));
  assert.ok(result.includes('[=[--literal\ncontents]=]'));
  assert.ok(result.includes("local c='--quoted'"));
  assert.ok(!result.includes('remove'));
  assert.equal(stripLuauComments(result),result);
  assert.equal(stripLuauComments('return 1--[[x]]+2'), 'return 1 +2');
});
