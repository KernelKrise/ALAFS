"""ALAFS MCP Server"""

from mcp.server.fastmcp import FastMCP

from constants import MCP_HOST, MCP_NAME, MCP_PORT
from helpers import list_dir
from log import logger
from models import ListDirectoryRequest, ListDirectoryResponse

# Initialize MCP server
mcp = FastMCP(
    MCP_NAME,
    host=MCP_HOST,
    port=MCP_PORT,
    json_response=True,
)


@mcp.tool()
async def list_directory(params: ListDirectoryRequest) -> ListDirectoryResponse:
    """List directory content, not recursive, relative path. Use '.' to list project directory.

    Args:
        params (ListDirectoryRequest): Target path to list.

    Returns:
        ListDirectoryResponse: Directory listing.
    """
    logger.info("Listing directory: %s", params.path)
    project_list = list_dir(params.full_path)
    return ListDirectoryResponse(objects=project_list)


if __name__ == "__main__":
    try:
        mcp.run(transport="sse")
    except KeyboardInterrupt:
        logger.info("Bye!")
