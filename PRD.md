# Product Requirements Document (PRD) - Bairro Seguro

## 1. Visão Geral do Produto
O **Bairro Seguro** é uma aplicação móvel desenvolvida em Flutter, focada em promover a segurança comunitária. O objetivo principal é permitir que os moradores de um bairro relatem e monitorem incidentes de segurança em tempo real, criando uma rede de vigilância colaborativa e informada.

## 2. Objetivos Estratégicos
- **Colaboração Comunitária:** Engajar moradores na proteção mútua do bairro.
- **Informação em Tempo Real:** Fornecer dados atualizados sobre ocorrências na região.
- **Prevenção:** Auxiliar na identificação de áreas de risco e padrões de criminalidade/incidentes.

## 3. Público-Alvo
- Moradores de bairros residenciais.
- Associações de moradores.
- Guardas comunitários e pessoal de segurança local.

## 4. Funcionalidades Principais (MVP)

### 4.1. Autenticação e Gestão de Usuários
- **Registro de Usuário:** Criação de conta com nome de usuário, e-mail e senha.
- **Login/Logout:** Acesso seguro à plataforma com persistência de token (JWT/DRF Token).
- **Perfil do Usuário:** Visualização e edição de dados cadastrais.

### 4.2. Relato de Incidentes
- **Seleção de Localização:** Integração com mapas (OpenStreetMap/Flutter Map) permitindo ao usuário marcar o local exato da ocorrência via GPS ou seleção manual.
- **Descrição do Incidente:** Campo de texto para detalhamento do ocorrido.
- **Nível de Gravidade:** Classificação da ocorrência em níveis (Baixo, Médio, Alto).
- **Envio de Dados:** Envio assíncrono para o backend via API REST.

### 4.3. Monitoramento de Incidentes
- **Lista de Incidentes:** Visualização de todas as ocorrências relatadas no bairro.
- **Mapa de Calor/Pontos:** (Planejado) Visualização geográfica dos incidentes para identificação de zonas de risco.

## 5. Requisitos Não Funcionais
- **Usabilidade:** Interface intuitiva e de fácil acesso para situações de urgência.
- **Performance:** Carregamento rápido de mapas e baixo consumo de dados móveis.
- **Estética:** Design moderno com suporte a Dark Mode e tipografia legível (Inter).
- **Segurança:** Comunicação criptografada com o backend e proteção de dados sensíveis dos usuários.

## 6. Stack Tecnológica
- **Frontend:** Flutter (Dart)
- **Mapas:** flutter_map / OpenStreetMap
- **Localização:** geolocator
- **Backend (API):** Django / Django REST Framework (identificado pelo padrão de URLs no `ApiService`)
- **Estilização:** Material 3 com esquemas de cores personalizados (Indigo).

## 7. Próximos Passos e Roadmap
- [ ] Implementar notificações push para alertas imediatos em áreas próximas.
- [ ] Adicionar suporte a fotos e vídeos nos relatos de incidentes.
- [ ] Implementar chat ou comentários para discussão de ocorrências específicas.
- [ ] Melhorar a filtragem de incidentes por data e categoria.
- [ ] Implementar sistema de verificação de autenticidade (upvote/downvote de relatos).

---
*Documento gerado para o projeto Bairro Seguro - 2024*
