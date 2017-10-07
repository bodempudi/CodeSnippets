--setting up environment
--first run this command for set up
npm i -g powerbi-visuals-tools

--install certificate
pbiviz --install-cert 


pbiviz new testVisual
cd testVisual
npm i -g typings
npm install powerbi-visuals-utils-dataviewutils --save
npm i d3
typings install d3 --global --save

//add the following to tsconfig.json
,"typings/index.d.ts"

//Add d3 reference to pbiviz.json to externalJS array
,"node_modules/d3/d3.min.js"
