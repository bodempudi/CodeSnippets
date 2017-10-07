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
