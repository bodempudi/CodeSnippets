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