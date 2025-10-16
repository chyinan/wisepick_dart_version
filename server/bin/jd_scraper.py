import asyncio
import json
import sys
from pyppeteer import launch
from pyppeteer_stealth import stealth

# [重要] 请将这里的长字符串替换成您自己的京东联盟Cookie
your_cookie = r'''jcap_dvzw_fp=Ihp-4nVOCxR82pqJzqu_XVX-xeOjt7WYeiSyZhF5D-W_eDMBhBjCy3jhcXkdheJE1cB0YVL5tI811sGn0xO2bg==; pinId=Dry4NQFLlB1maIWDXaqhT4-YzldwRazB; unick=JasonChen628; __jdu=1758291453435753308673; shshshfpa=53aa73c3-3bce-3ec1-c2eb-e0ade7ba6ca8-1758291453; shshshfpx=53aa73c3-3bce-3ec1-c2eb-e0ade7ba6ca8-1758291453; track=c7489345-a813-e98e-1bf0-69a5cc8e3762; jdd69fo72b8lfeoe=3LU6VVHD7CYXR37RQLQ3GTJVCY2PPJT3BUZHRVQI5UCIEDDPC7X2COT32PPB2LFYDQ2COSZFPX4IK44XCPTONA5HRY; areaId=19; ipLoc-djd=19-1601-50258-129167; mba_muid=1758291453435753308673; language=zh_CN; _tp=l3iEQTirKbFmMQk35x77Me3Y6z1xPYVlAf4XGdR8278%3D; _pst=jd_7IG8jr31vd3Ek0o; unpl=JF8EAK1nNSttCBldUkgHGhMXSFkEW1oKSEQFPGBVXF8LGFQDTAROR0B7XlVdWRRLFh9vYxRUWVNOUQ4bBCsSEHteVVxbCk0WBm9uNWRaWEIZRElPKxEQe1xkXlsMQhQLb2IBVlhaT1IBGQAaGxdNX2RfbQ9LHjNvZgRdVVpCUgIcBhoSFHttVW5cOEonQgFnBFRdUExXBlYCHRYZSFVUW1kKThUHaWMHVlxRTFIHKwMrEQ; warehistory="10089387665015,"; retina=0; cid=9; webp=1; visitkey=6521879088185004784; autoOpenApp_downCloseDate_autoOpenApp_autoPromptly=1760514256887_1; __wga=1760514257255.1760514257255.1760514257255.1760514257255.1.1; PPRD_P=UUID.1758291453435753308673-LOGID.1760514257261.1743795116; sc_width=1685; __jdv=209449046|direct|-|none|-|1760602909477; 3AB9D23F7A4B3CSS=jdd03T77XIKBWZ22OU4GO4J3GLKM6DJLT2LVCEBXMYOPYP2HKPQMIE3M3DJEJNKXNEDWHW3EUIEB5YJ32MOUAPYQDKU3MNEAAAAMZ5QOHRRYAAAAACNKOCHMCJH6ZIEX; _gia_d=1; thor=0AA108F9F77B0A664BEA806EAC6E185712DE405A4F19D1BD64B64EEBC4A5C5F2ECBD369FE078FE00D410C0B2868A6825E3638C4E85F1098E22F5450B39A0A09C6ADC499059B70C923FF2B5FC8A2DDEBA2E407123AA40990BF3A6B6E212B3961E4D01422A7A1C1DC804926C82CFF4B0DEC9C6DD7CEC823CA6D785E74CF9308AA7995E5399098BDE6184ED5DA41230B23B968B1142D3F7AFC9E37E27DA92EAE4F3; flash=3_-YpPdFrSxySwjjwa3CQlEWIcYEI64TC-3AEQKNd0xXdTMcoIN-vxo-k-noelXvAIVK-k5xbR4asDhz1R9a-sNNMaLiA7B8cqkdhF7KgYCTlc1-Vo80leq-8j6kcUmNI2asLpjECUFRqSoa4eX1H_XQ6jbkqFodhRUVzMEm4yfOSEMmhrJHhcKnDB; light_key=AASBKE7rOxgWQziEhC_QY6yaD5zHvkjBptoNArIAa1wFjopFLkFerIfRlrds-qwjgDtsXh_v; pin=jd_7IG8jr31vd3Ek0o; ceshi3.com=201; logining=1; 3AB9D23F7A4B3C9B=T77XIKBWZ22OU4GO4J3GLKM6DJLT2LVCEBXMYOPYP2HKPQMIE3M3DJEJNKXNEDWHW3EUIEB5YJ32MOUAPYQDKU3MNE; __jda=209449046.1758291453435753308673.1758291453.1760533850.1760602909.47; __jdc=209449046; shshshfpb=BApXSp2MU7_xAXN3TyYnQdXAiidpcfN1yBhpoE3xn9xJ1Mrxd0I4zsnqL7E8; __jdb=209449046.9.1758291453435753308673|47.1760602909; sdtoken=AAbEsBpEIOVjqTAKCQtvQu17tM85wh2Q9YcdFqW9AGxz__x4RX7nSEbmB-XzOAIvAj61hEQo-UmziyKKjd0BItcxH9YMARxqEG8fILESm3FPyDemKRPuMnCBiKxexPwT8yT7rF8NJKDVYg'''

def parse_cookie_string(cookie_string):
    cookies = []
    for part in cookie_string.split(';'):
        if '=' in part:
            name, value = part.strip().split('=', 1)
            cookies.append({'name': name, 'value': value, 'domain': '.jd.com'})
    return cookies

async def main(material_info):
    browser = await launch(
        headless=True,
        # Windows用户可能需要指定Chrome路径
        executablePath=r"C:\Program Files\Google\Chrome\Application\chrome.exe"
    )
    page = await browser.newPage()
    
    # 启用深度伪装
    await stealth(page)

    # 设置Cookie
    cookies = parse_cookie_string(your_cookie)
    await page.setCookie(*cookies)

    await page.goto('https://union.jd.com/proManager/custompromotion', {'waitUntil': 'networkidle0'})

    try:
        # 输入和点击操作
        input_selector = 'div.el-textarea textarea'
        await page.waitForSelector(input_selector, {'timeout': 10000})
        await page.type(input_selector, material_info, {'delay': 100})
        await asyncio.sleep(1)

        await page.evaluate(r'''() => {
            const buttons = document.querySelectorAll('.superBtn button.el-button--primary');
            for (const button of buttons) {
                if (button.textContent.trim().includes('获取推广链接')) {
                    button.click();
                    return;
                }
            }
            throw new Error('Could not find button by text');
        }''')
        
        # 等待结果出现
        result_selector = '.result-text'
        await page.waitForSelector(result_selector, {'timeout': 15000})
        await asyncio.sleep(2) # 等待文本渲染稳定

        # 提取结果
        content = await page.evaluate(f'''() => document.querySelector('{result_selector}').innerText''')
        
        # 将结果以JSON格式打印到标准输出
        result_data = {'status': 'success', 'data': content}
        # [最终修正] 指定UTF-8编码，解决Windows下的GBK编码错误
        sys.stdout.reconfigure(encoding='utf-8')
        print(json.dumps(result_data, ensure_ascii=False))

    except Exception as e:
        error_data = {'status': 'error', 'message': str(e)}
        # [最终修正] 指定UTF-8编码，解决Windows下的GBK编码错误
        sys.stdout.reconfigure(encoding='utf-8')
        print(json.dumps(error_data, ensure_ascii=False))
        
    finally:
        await asyncio.sleep(5) # 停留5秒方便观察
        await browser.close()

if __name__ == '__main__':
    if len(sys.argv) > 1:
        material = sys.argv[1]
        asyncio.get_event_loop().run_until_complete(main(material))
    else:
        # 如果没有提供参数，则打印错误
        error_info = {'status': 'error', 'message': 'No SKU/URL provided'}
        # [最终修正] 指定UTF-8编码，解决Windows下的GBK编码错误
        sys.stdout.reconfigure(encoding='utf-8')
        print(json.dumps(error_info))
