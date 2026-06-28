from pathlib import Path
from html import escape


OUT = Path(__file__).resolve().parents[1] / "www" / "diagrams"


DIAGRAMS = {
    "overview": {
        "title": "World3-03 Subsystem Overview",
        "subtitle": "Major feedback structure linking population, capital, agriculture, pollution, and resources",
        "nodes": [
            ("Population", 170, 170, "stock"),
            ("Industrial Capital", 430, 150, "stock"),
            ("Service Capital", 690, 180, "stock"),
            ("Food Production", 430, 380, "process"),
            ("Nonrenewable Resources", 170, 420, "stock"),
            ("Persistent Pollution", 690, 420, "stock"),
            ("Human Welfare", 430, 610, "outcome"),
        ],
        "edges": [
            ("Population", "Industrial Capital", "+", "labor demand"),
            ("Industrial Capital", "Food Production", "+", "agricultural inputs"),
            ("Food Production", "Population", "+", "food per capita"),
            ("Industrial Capital", "Nonrenewable Resources", "-", "resource use"),
            ("Nonrenewable Resources", "Industrial Capital", "-", "extraction burden"),
            ("Industrial Capital", "Persistent Pollution", "+", "material throughput"),
            ("Persistent Pollution", "Food Production", "-", "yield stress"),
            ("Service Capital", "Human Welfare", "+", "services"),
            ("Food Production", "Human Welfare", "+", "nutrition"),
            ("Persistent Pollution", "Human Welfare", "-", "health impact"),
        ],
    },
    "human_fertility": {
        "title": "Human Fertility",
        "subtitle": "How income, services, perceived lifetime, and fertility control shape births",
        "nodes": [
            ("Population 15-44", 160, 245, "stock"),
            ("Desired Family Size", 405, 120, "process"),
            ("Fertility Control", 660, 160, "process"),
            ("Total Fertility", 405, 325, "process"),
            ("Births", 660, 345, "flow"),
            ("Population", 405, 520, "stock"),
        ],
        "edges": [
            ("Population 15-44", "Births", "+", "reproductive cohort"),
            ("Desired Family Size", "Total Fertility", "+", "desired children"),
            ("Fertility Control", "Total Fertility", "-", "effectiveness"),
            ("Total Fertility", "Births", "+", "birth rate"),
            ("Births", "Population", "+", "adds people"),
            ("Population", "Desired Family Size", "-", "social adjustment"),
        ],
    },
    "land_fertility": {
        "title": "Land Fertility",
        "subtitle": "Fertility degrades under pollution pressure and regenerates through maintenance",
        "nodes": [
            ("Land Fertility", 430, 220, "stock"),
            ("Fertility Degradation", 170, 360, "flow"),
            ("Fertility Regeneration", 690, 360, "flow"),
            ("Persistent Pollution", 170, 150, "stock"),
            ("Land Maintenance", 690, 150, "process"),
            ("Land Yield", 430, 500, "outcome"),
        ],
        "edges": [
            ("Persistent Pollution", "Fertility Degradation", "+", "degradation rate"),
            ("Fertility Degradation", "Land Fertility", "-", "loss"),
            ("Land Maintenance", "Fertility Regeneration", "+", "repair"),
            ("Fertility Regeneration", "Land Fertility", "+", "rebuilds fertility"),
            ("Land Fertility", "Land Yield", "+", "yield base"),
        ],
    },
    "food_production": {
        "title": "Food Production",
        "subtitle": "Food depends on land, yield, inputs, capital allocation, and processing losses",
        "nodes": [
            ("Arable Land", 160, 230, "stock"),
            ("Agricultural Inputs", 430, 130, "stock"),
            ("Land Yield", 430, 315, "process"),
            ("Food Production", 690, 315, "flow"),
            ("Population", 160, 500, "stock"),
            ("Food Per Capita", 430, 520, "outcome"),
            ("Industrial Output", 690, 130, "process"),
        ],
        "edges": [
            ("Industrial Output", "Agricultural Inputs", "+", "investment"),
            ("Agricultural Inputs", "Land Yield", "+", "inputs/hectare"),
            ("Arable Land", "Food Production", "+", "harvested land"),
            ("Land Yield", "Food Production", "+", "yield"),
            ("Food Production", "Food Per Capita", "+", "food supply"),
            ("Population", "Food Per Capita", "-", "dilution"),
        ],
    },
    "labor_force": {
        "title": "Utilization of the Labor Force",
        "subtitle": "Jobs, labor force, and utilization affect capital use and output",
        "nodes": [
            ("Population 15-64", 170, 220, "stock"),
            ("Labor Force", 430, 220, "process"),
            ("Jobs", 690, 220, "process"),
            ("Labor Utilization", 430, 420, "outcome"),
            ("Capital Utilization", 690, 420, "outcome"),
            ("Industrial Output", 430, 600, "flow"),
        ],
        "edges": [
            ("Population 15-64", "Labor Force", "+", "participation"),
            ("Jobs", "Labor Utilization", "+", "job capacity"),
            ("Labor Force", "Labor Utilization", "-", "available workers"),
            ("Labor Utilization", "Capital Utilization", "+", "utilization delay"),
            ("Capital Utilization", "Industrial Output", "+", "effective capital"),
        ],
    },
    "population_dynamics": {
        "title": "Population Dynamics",
        "subtitle": "Age cohorts mature, births add young people, and deaths remove people",
        "nodes": [
            ("Ages 0-14", 160, 240, "stock"),
            ("Ages 15-44", 390, 240, "stock"),
            ("Ages 45-64", 620, 240, "stock"),
            ("Ages 65+", 820, 240, "stock"),
            ("Births", 160, 500, "flow"),
            ("Deaths", 620, 500, "flow"),
            ("Life Expectancy", 390, 500, "outcome"),
        ],
        "edges": [
            ("Births", "Ages 0-14", "+", "birth inflow"),
            ("Ages 0-14", "Ages 15-44", "+", "maturation"),
            ("Ages 15-44", "Ages 45-64", "+", "maturation"),
            ("Ages 45-64", "Ages 65+", "+", "maturation"),
            ("Life Expectancy", "Deaths", "-", "mortality"),
            ("Deaths", "Ages 0-14", "-", "mortality"),
            ("Deaths", "Ages 15-44", "-", "mortality"),
            ("Deaths", "Ages 45-64", "-", "mortality"),
            ("Deaths", "Ages 65+", "-", "mortality"),
        ],
    },
    "pollution_dynamics": {
        "title": "Pollution Dynamics",
        "subtitle": "Industrial and agricultural activity generate persistent pollution, which affects health and yield",
        "nodes": [
            ("Industrial Output", 170, 160, "process"),
            ("Agricultural Inputs", 170, 380, "process"),
            ("Pollution Generation", 430, 270, "flow"),
            ("Persistent Pollution", 690, 270, "stock"),
            ("Assimilation", 690, 500, "flow"),
            ("Life Expectancy", 430, 520, "outcome"),
            ("Land Yield", 170, 560, "outcome"),
        ],
        "edges": [
            ("Industrial Output", "Pollution Generation", "+", "industrial emissions"),
            ("Agricultural Inputs", "Pollution Generation", "+", "agricultural materials"),
            ("Pollution Generation", "Persistent Pollution", "+", "appears after delay"),
            ("Persistent Pollution", "Assimilation", "+", "assimilated stock"),
            ("Assimilation", "Persistent Pollution", "-", "removal"),
            ("Persistent Pollution", "Life Expectancy", "-", "health impact"),
            ("Persistent Pollution", "Land Yield", "-", "yield impact"),
        ],
    },
    "service_investment": {
        "title": "Investments in the Service Sector",
        "subtitle": "Industrial output allocated to services builds service capital and service output",
        "nodes": [
            ("Industrial Output", 160, 250, "flow"),
            ("Fraction to Services", 410, 145, "process"),
            ("Service Investment", 410, 345, "flow"),
            ("Service Capital", 660, 345, "stock"),
            ("Service Output", 660, 545, "flow"),
            ("Health & Fertility Services", 410, 545, "outcome"),
        ],
        "edges": [
            ("Industrial Output", "Service Investment", "+", "available output"),
            ("Fraction to Services", "Service Investment", "+", "allocation"),
            ("Service Investment", "Service Capital", "+", "capital growth"),
            ("Service Capital", "Service Output", "+", "output capacity"),
            ("Service Output", "Health & Fertility Services", "+", "service per capita"),
        ],
    },
    "nonrenewable_resources": {
        "title": "Utilization of Nonrenewable Natural Resources",
        "subtitle": "Resource use depletes the stock and raises extraction burden as resources fall",
        "nodes": [
            ("Nonrenewable Resources", 250, 245, "stock"),
            ("Resource Use Rate", 560, 245, "flow"),
            ("Population", 250, 470, "stock"),
            ("Industrial Output Per Capita", 560, 470, "process"),
            ("Capital to Extraction", 800, 245, "process"),
            ("Industrial Output", 800, 470, "flow"),
        ],
        "edges": [
            ("Population", "Resource Use Rate", "+", "people"),
            ("Industrial Output Per Capita", "Resource Use Rate", "+", "resource multiplier"),
            ("Resource Use Rate", "Nonrenewable Resources", "-", "depletion"),
            ("Nonrenewable Resources", "Capital to Extraction", "-", "scarcity burden"),
            ("Capital to Extraction", "Industrial Output", "-", "less productive capital"),
        ],
    },
    "arable_land": {
        "title": "Arable Land Dynamics",
        "subtitle": "Arable land expands through development and contracts through erosion and urban use",
        "nodes": [
            ("Potentially Arable Land", 160, 250, "stock"),
            ("Land Development", 430, 250, "flow"),
            ("Arable Land", 690, 250, "stock"),
            ("Land Erosion", 690, 475, "flow"),
            ("Urban-Industrial Land", 430, 475, "stock"),
            ("Population & Industry", 160, 475, "process"),
        ],
        "edges": [
            ("Potentially Arable Land", "Land Development", "+", "land available"),
            ("Land Development", "Arable Land", "+", "adds land"),
            ("Land Development", "Potentially Arable Land", "-", "drawdown"),
            ("Arable Land", "Land Erosion", "+", "erosion base"),
            ("Land Erosion", "Arable Land", "-", "loss"),
            ("Population & Industry", "Urban-Industrial Land", "+", "land required"),
            ("Urban-Industrial Land", "Arable Land", "-", "conversion"),
        ],
    },
    "life_expectancy": {
        "title": "Life Expectancy",
        "subtitle": "Life expectancy integrates food, services, pollution, and crowding effects",
        "nodes": [
            ("Food Per Capita", 170, 170, "outcome"),
            ("Health Services", 430, 170, "outcome"),
            ("Persistent Pollution", 690, 170, "stock"),
            ("Crowding", 170, 420, "process"),
            ("Life Expectancy", 430, 420, "outcome"),
            ("Mortality Rates", 690, 420, "flow"),
            ("Population", 430, 615, "stock"),
        ],
        "edges": [
            ("Food Per Capita", "Life Expectancy", "+", "nutrition"),
            ("Health Services", "Life Expectancy", "+", "care"),
            ("Persistent Pollution", "Life Expectancy", "-", "toxicity"),
            ("Crowding", "Life Expectancy", "-", "urban pressure"),
            ("Life Expectancy", "Mortality Rates", "-", "mortality"),
            ("Mortality Rates", "Population", "-", "deaths"),
            ("Population", "Crowding", "+", "urban fraction"),
        ],
    },
}


def node_style(kind):
    if kind == "stock":
        return "#213d46", "#8fb8a5"
    if kind == "flow":
        return "#4d2630", "#d28a93"
    if kind == "outcome":
        return "#493f22", "#d9c27f"
    return "#24314a", "#9eb0d6"


def draw_node(label, x, y, kind):
    fill, stroke = node_style(kind)
    return f"""
    <g class="node">
      <rect x="{x-82}" y="{y-30}" width="164" height="60" rx="10" fill="{fill}" stroke="{stroke}" stroke-width="2"/>
      <text x="{x}" y="{y-4}" text-anchor="middle">{escape(label)}</text>
      <text x="{x}" y="{y+16}" text-anchor="middle" class="kind">{kind}</text>
    </g>"""


def draw_edge(nodes, source, target, sign, label):
    sx, sy, _ = nodes[source]
    tx, ty, _ = nodes[target]
    mx = (sx + tx) / 2
    my = (sy + ty) / 2
    dx = tx - sx
    dy = ty - sy
    c1x = sx + dx * 0.35
    c1y = sy + dy * 0.15
    c2x = sx + dx * 0.65
    c2y = sy + dy * 0.85
    sign_color = "#8fb8a5" if sign == "+" else "#d28a93"
    return f"""
    <path class="edge" d="M {sx} {sy} C {c1x:.1f} {c1y:.1f}, {c2x:.1f} {c2y:.1f}, {tx} {ty}" marker-end="url(#arrow)"/>
    <g class="edge-label">
      <circle cx="{mx:.1f}" cy="{my:.1f}" r="13" fill="{sign_color}"/>
      <text x="{mx:.1f}" y="{my+5:.1f}" text-anchor="middle" class="sign">{sign}</text>
      <text x="{mx:.1f}" y="{my+29:.1f}" text-anchor="middle" class="caption">{escape(label)}</text>
    </g>"""


def svg_for(key, spec):
    nodes = {label: (x, y, kind) for label, x, y, kind in spec["nodes"]}
    content = []
    for source, target, sign, label in spec["edges"]:
        content.append(draw_edge(nodes, source, target, sign, label))
    for label, x, y, kind in spec["nodes"]:
        content.append(draw_node(label, x, y, kind))
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 980 720" role="img" aria-labelledby="title-{key} desc-{key}">
  <title id="title-{key}">{escape(spec["title"])}</title>
  <desc id="desc-{key}">{escape(spec["subtitle"])}</desc>
  <defs>
    <marker id="arrow" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto" markerUnits="strokeWidth">
      <path d="M0,0 L0,6 L9,3 z" fill="#d7dfdc"/>
    </marker>
    <radialGradient id="bg" cx="30%" cy="20%" r="80%">
      <stop offset="0" stop-color="#243842"/>
      <stop offset="1" stop-color="#101418"/>
    </radialGradient>
  </defs>
  <style>
    .title {{ font: 700 30px Arial, sans-serif; fill: #f7f7f4; }}
    .subtitle {{ font: 15px Arial, sans-serif; fill: #b8c5c0; }}
    .node text {{ font: 700 14px Arial, sans-serif; fill: #f7f7f4; }}
    .node .kind {{ font: 11px Arial, sans-serif; fill: #c6d0cc; opacity: .85; text-transform: uppercase; }}
    .edge {{ fill: none; stroke: #d7dfdc; stroke-width: 2.2; opacity: .72; }}
    .sign {{ font: 700 17px Arial, sans-serif; fill: #101418; }}
    .caption {{ font: 11px Arial, sans-serif; fill: #c7d1cd; }}
  </style>
  <rect width="980" height="720" rx="18" fill="url(#bg)"/>
  <path d="M70 620 C220 560 320 450 430 335 C560 200 710 145 900 180" fill="none" stroke="#b04a5a" stroke-width="4" opacity=".16"/>
  <path d="M70 580 C270 600 450 540 610 455 C740 386 835 390 900 430" fill="none" stroke="#d9c27f" stroke-width="3" opacity=".16"/>
  <text x="52" y="58" class="title">{escape(spec["title"])}</text>
  <text x="52" y="86" class="subtitle">{escape(spec["subtitle"])}</text>
  {"".join(content)}
</svg>
"""


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for key, spec in DIAGRAMS.items():
        (OUT / f"{key}.svg").write_text(svg_for(key, spec), encoding="utf-8")
    print(OUT)


if __name__ == "__main__":
    main()
