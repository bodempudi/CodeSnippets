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

//tsconfig.json
{
  "compilerOptions": {
    "allowJs": true,
    "emitDecoratorMetadata": true,
    "experimentalDecorators": true,
    "target": "ES5",
    "sourceMap": true,
    "out": "./.tmp/build/visual.js"
  },
  "files": [
    ".api/v1.6.0/PowerBI-visuals.d.ts",
    "node_modules/powerbi-visuals-utils-dataviewutils/lib/index.d.ts",
    "src/settings.ts",
    "typings/index.d.ts",
    "src/visual.ts"
  ]
}

//pbiviz.json
 "externalJS": [
    "node_modules/powerbi-visuals-utils-dataviewutils/lib/index.js",
    "node_modules/d3/d3.min.js"
  ]

//visual.ts
  
        private target: HTMLElement;
        private settings: VisualSettings;
        private svg: d3.Selection<SVGElement>;
  //contr
  
  let svg = this.svg = d3.select(options.element)
                .append('svg').classed('liquidFillGauge', true);

            this.svg.append("circle")
                .attr("cx", 50)
                .attr("cy", 50)
                .attr("r", 50)
                .style("fill", 'green');
----------------------
npm i -g typings (will install typings, Typings is the simple way to manage and install TypeScript definitions)

Npm install d3@3 (add to pbiviz.json)

Npm install @types/d3@3 (add to tsconfig.json befor visual.ts)

Npm install jquery

Npm install @types/jquery@2.0.47 

npm install powerbi-visuals-utils-dataviewutils 

npm install powerbi-visuals-utils-svgutils –save

npm install powerbi-visuals-utils-formatutils --save 
