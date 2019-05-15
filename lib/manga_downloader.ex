defmodule MangaDownloader do
  defp get_image_urls(url) do
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        urls = body
          |> Floki.find("img.lovea.img-responsive")
          |> Floki.attribute("src")
        {:ok, urls}
      
      {:error, _} ->
        get_image_urls(url)
    end
  end

  defp download_images(urls) do
    parent = self()
    for i <- 0..length(urls)-1, do: spawn fn -> get_save_image(i, Enum.at(urls, i), parent) end
  end

  defp get_save_image(i, url, parent) do
    case HTTPoison.get(url) do
      {:ok, result} ->
        File.write!(Integer.to_string(i) <> ".jpg", result.body)
        send(parent, {:ok, i})
      {:error, _} ->
        get_save_image(i, url, parent)
    end
  end

  def block_till_receive() do
    receive do
      {:ok, page_num} -> IO.puts(Integer.to_string(page_num) <> ".jpg Downloaded!")
    end
  end

  def scrape() do
    url = IO.gets("Enter manga page URL : ")
    {:ok, urls} = get_image_urls(url)
    pids = download_images(urls)
    for _ <- pids, do: block_till_receive()
  end
end
