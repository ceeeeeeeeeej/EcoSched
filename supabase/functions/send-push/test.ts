Deno.serve(async (req: Request) => {
    if (req.method === 'OPTIONS') {
        return new Response(null, {
            status: 204,
            headers: {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'POST, OPTIONS',
                'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
            },
        });
    }

    return new Response(JSON.stringify({ hello: "world" }), {
        headers: { "Content-Type": "application/json", 'Access-Control-Allow-Origin': '*' },
    });
});
