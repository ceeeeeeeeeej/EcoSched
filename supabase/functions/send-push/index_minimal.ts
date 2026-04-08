// Minimal Deno Heartbeat
Deno.serve(async (req) => {
  return new Response("OK", { status: 200 });
});
