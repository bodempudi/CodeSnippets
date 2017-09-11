--setting up environment
--first run this command for set up
npm i -g powerbi-visuals-tools

--install certificate
pbiviz --install-cert 


pbiviz new testVisual
cd testVisual
npm i -g typings
npm i d3@3.5.5 --save
typings install d3=github:DefinitelyTyped/DefinitelyTyped/d3/d3.d.ts#6e2f2280ef16ef277049d0ce8583af167d586c59 --global --save

//add the following to tsconfig.json
,"typings/index.d.ts"

//Add d3 reference to pbiviz.json to externalJS array
,"node_modules/d3/d3.min.js"

npm install -g power-custom-visuals
npm install typescript
npm install d3 --save
npm install less
pbiviz --install-cert
npm install powerbi-visuals-utils-dataviewutils --save

npm @types/d3@3 --save

typings install d3 --source dt --global
typings search d3
npm i -g typings
npm i d3@3.5.5 --save
typings install dt~d3 --save --global
