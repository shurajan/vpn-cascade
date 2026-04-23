// deno run --allow-net --allow-write app.ts http://site.com

const url = Deno.args[0];

let current = url;
let output = "";

for (let i = 0; i < 10; i++) {
  const res = await fetch(current, {
    redirect: "manual",
  });

  output += `${res.status} ${current}\n`;

  const next = res.headers.get("location");

  if (!next) break;

  current = new URL(next, current).href;
}

await Deno.writeTextFile("redirects.txt", output);
console.log("saved");
