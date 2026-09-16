import os
import re

providers_dir = 'lib/providers'
for filename in os.listdir(providers_dir):
    if filename.endswith('.dart'):
        filepath = os.path.join(providers_dir, filename)
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Replace _dio with ApiService.dio
        content = re.sub(r'\b_dio\b', 'ApiService.dio', content)
        # Remove final Dio ApiService.dio = Dio();
        content = re.sub(r'final Dio ApiService\.dio = Dio\(\);', '', content)
        # Remove options: _authOptions
        content = re.sub(r',\s*options:\s*_authOptions', '', content)
        content = re.sub(r'options:\s*_authOptions\s*,?', '', content)
        
        # Add import for api_service if missing
        if 'ApiService.dio' in content and 'api_service.dart' not in content:
            content = "import 'package:quiropractico_front/services/api_service.dart';\n" + content
            
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
