#include <telnet.h>
#include <telnet_protocol.h>

enum parse_state_t {
  PARSING_DATA,
  PARSING_CMD,
  PARSING_OPTIONS,
  PARSING_REQUEST,
  PARSING_NOTIFICATION,
  PARSING_EOL
};


void init_telnet_parse_state(int *parse_state)
{
  *parse_state = PARSING_DATA;
}

int parse_telnet_buffer(char *data,
                        int len,
                        int *parse_state,
                        int *close_request)
{
  int i = 0;
  int j = 0;

  *close_request = 0;

  while (i<len) {
    switch (*parse_state) {
    case PARSING_CMD:
      switch (data[i])
        {
        case SB:
          *parse_state = PARSING_OPTIONS;
          break;
        case SE:
          *parse_state = PARSING_DATA;
          break;
        case WILL:
        case WONT:
          *parse_state = PARSING_REQUEST;
          break;
        case DO:
        case DONT:
          *parse_state = PARSING_NOTIFICATION;
          break;
        case IP:
          *close_request = 1;
          return j;
        default:
          // unsupported command - ignore
          *parse_state = PARSING_DATA;
          break;
        };
      i++;
      break;
    case PARSING_NOTIFICATION:
      // just ignore everything the other side tells us for now
      *parse_state = PARSING_DATA;
      i++;
      break;
    case PARSING_REQUEST:
      *parse_state = PARSING_DATA;
      i++;
      break;
    case PARSING_OPTIONS:
      if (data[i] == IAC)
        *parse_state = PARSING_CMD;
      i++;
      break;
    case PARSING_DATA:
      switch (data[i])
        {
        case IAC:
          *parse_state = PARSING_CMD;
          break;
        case CR:
          data[j] = CR;
          j++;
          *parse_state = PARSING_EOL;
          break;
        default:
          if (data[i] != NUL) {
            data[j] = data[i];
            j++;
          }
          break;
        }
      i++;
      break;
    case PARSING_EOL:
      if (data[i] == LF) {
        data[j] = LF;
        j++;
        *parse_state = PARSING_DATA;
      }
      i++;
      break;
    }
  }

  return j;
}

int parse_telnet_bufferi(char *data,
                         int i,
                        int len,
                        int *parse_state,
                        int *close_request)
{
  return parse_telnet_buffer(data+i,len,parse_state,close_request);
}
